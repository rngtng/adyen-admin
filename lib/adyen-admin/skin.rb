require 'tmpdir'
require 'zip/zip'

module Adyen
  module Admin
    class Skin
      UPLOAD       = "https://ca-test.adyen.com/ca/ca/skin/uploadskin.shtml?skinCode=%s"
      DOWNLOAD     = "https://ca-test.adyen.com/ca/ca/skin/downloadskinsubmit.shtml?skinCode=%s"
      TEST         = "https://ca-test.adyen.com/ca/ca/skin/testpayment.shtml?skinCode=%s"

      VERSION_TEST = "https://test.adyen.com/hpp/version.shtml?skinCode=%s"
      VERSION_LIVE = "https://live.adyen.com/hpp/version.shtml?skinCode=%s"
      PUBLISH      = "https://ca-test.adyen.com/ca/ca/skin/publishskin.shtml?skinCode=%s"
      SKINS        = "https://ca-test.adyen.com/ca/ca/skin/skins.shtml"

      attr_accessor :code, :name, :path

      def initialize(attributes = {})
        attributes.each do |key, value|
          send("#{key}=", value)
        end

        if !path && code
          path = skin_path([code,name].join("-"))
        end

        raise ArgumentError unless code
      end

      def self.all(path = nil)
        all_remote + all_local(path)
      end

      def self.all_remote
        @@skins_remote ||= begin
          page = Adyen::Admin.client.get(SKINS)
          page.search(".data tbody tr").map do |node|
            Skin.new({
              :code => node.search("a")[0].content.strip,
              :name => node.search("td")[1].content.strip
            })
          end
        end
      end

      def self.all_local(path)
        Dir[File.join(path.to_s, "*")].map do |path|
          Skin.new(:path => path) rescue nil
        end.compact
      end

      def self.find(skin_code)
        all.select do |skin|
          skin.code == skin_code
        end.first
      end

      ##################################
      def path=(path)
        if Skin.is_skin_path?(path)
          code, name = File.basename(path).split("-").reverse
          self.code ||= code
          self.name ||= name
          raise ArgumentError if code && self.code != code
          @path = path
        end
      end

      def version(scope = :local)
        case scope
        when :test
          page = Adyen::Admin.client.get(VERSION_TEST % code)
          page.search("body p").first.content.scan(/Version:(\d+)/).flatten.first.to_i
        when :live
          page = Adyen::Admin.client.get(VERSION_LIVE % code)
          page.search("body p").first.content.scan(/Version:(\d+)/).flatten.first.to_i
        else
          page = Adyen::Admin.client.get(TEST % code)
          page.search(".data tr td")[2].content.to_i
        end
      end

      def test_url(options = {})
        page = Adyen::Admin.client.get(TEST % code)
        page = Adyen::Admin.client.submit(page.form.tap do |form|
          #:amount => 199, :currency => :shopper_locale, :country_code, :merchant_reference, :merchant_account, :system, :skip, :one_page
        end)
        Addressable::URI.parse(page.form.action).tap do |uri|
          uri.query_values = page.form.fields.inject({}) { |hash, node|
            hash[node.name] = node.value; hash
          }
        end
      end

      def zip_filename
        "#{code}.zip"
      end

      ##########################################

      # http://stackoverflow.com/questions/4360043/using-wwwmechanize-to-download-a-file-to-disk-without-loading-it-all-in-memory
      # Adyen::Admin.client.pluggable_parser.default = Mechanize::FileSaver
      def download
        Adyen::Admin.client.download(DOWNLOAD % code, zip_filename)

        if path
          # create backup of current
          # compile
        end
        # unzip
        zip_filename
      end

      def compile
        raise ArgumentError unless path

        File.join(Dir.tmpdir, "#{code}.zip").tap do |filename|
          `rm -rf #{filename}`
          Zip::ZipFile.open(filename, 'w') do |zipfile|
            Dir["#{path}/**/**"].each do |file|
              next if file.include?(".yml")
              next if file.include?(".erb")
              zipfile.add(file.sub(path, code), file)
            end

            if dir = skin_path("base")
              Dir["#{dir}/**/**"].each do |file|
                begin
                  next if file.include?(".yml")
                  next if file.include?(".erb")
                  zipfile.add(file.sub(dir, code), file)
                rescue Zip::ZipEntryExistsError
                  # NOOP
                end
              end
            end
          end
        end
      end

      # http://stackoverflow.com/questions/3420587/ruby-mechanize-multipart-form-with-file-upload-to-a-mediawiki
      def upload
        file = self.compile
        page = Adyen::Admin.client.get(UPLOAD % code)
        page = Adyen::Admin.client.submit(page.form.tap do |form|
          form.file_uploads.first.file_name = file
        end)
        form = page.form
        page = form.submit(page.form.button_with(:name => 'submit'))
      end

      def publish
        raise ArgumentError unless code

        page = Adyen::Admin.client.get(PUBLISH % code)
        page = Adyen::Admin.client.submit(page.form.tap do |form|
        end)
      end

      #################################

      # def guess_path
      #   [code, "#{code}-#{name}"].each do |file_name|
      #     dir = skin_path(file_name)
      #     return dir if File.exists?(dir)
      #   end
      #   nil
      # end

      def skin_path(skin_code)
        skin_dir = path ? File.dirname(path) : Adyen::Admin.skin_dir
        File.join(skin_dir, skin_code).tap do |path|
          return nil unless File.directory?(path)
        end
      end

      def ==(skin)
        self.code == skin.code
      end

      private
      def self.is_skin_path?(path)
        %w(skin.html.erb inc css js).each do |sub_path|
          return true if File.exists?(File.join(path, sub_path))
        end
        false
      end
    end
  end
end

