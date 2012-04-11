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

      attr_reader :code, :name, :path

      def initialize(attributes = {})
        attributes.each do |key, value|
          send("#{key}=", value)
        end

        self.path ||= File.join(Skin.default_path, [name,code].compact.join("-"))

        raise ArgumentError unless code
      end

      def self.default_path
        @default_path || "."
      end

      def self.default_path=(path)
        @default_path = path
      end

      # union remote and local skins. Local skins are frozen to
      # indicate no availble remote counter part which avoid update
      def self.all(path = Skin.default_path)
        {}.tap do |hash|
          self.all_remote.each do |skin|
            hash[skin.code] = skin unless hash[skin.code]
          end
          self.all_local(path).each do |skin|
            hash[skin.code] = skin unless hash[skin.code]
          end
        end.values
      end

      # fetch all remote skins
      def self.all_remote
        @skins_remote ||= begin
          page = Adyen::Admin.get(SKINS)
          page.search(".data tbody tr").map do |node|
            Skin.new({
              :code => node.search("a")[0].content.strip,
              :name => node.search("td")[1].content.strip,
            })
          end
        end
      end

      # fetch all local skins
      def self.all_local(path = Skin.default_path)
        Dir[File.join(path.to_s, "*")].map do |path|
          Skin.new(:path => path).freeze rescue nil
        end.compact
      end

      # find a skin within remote + local ones
      def self.find(skin_code)
        self.all.select do |skin|
          skin.code == skin_code
        end.first
      end

      def self.purge_cache
        @skins_remote = nil
      end

      ##################################

      def path=(new_path)
        if Skin.is_skin_path?(new_path)
          new_code, new_name = File.basename(new_path).split("-").reverse
          self.code ||= new_code
          self.name ||= new_name
          raise ArgumentError if self.code && self.code != new_code
          @path = new_path
        end
      end

      ##################################

      def version(scope = :local)
        case scope
        when :test
          page = Adyen::Admin.get(VERSION_TEST % code)
          page.search("body p").first.content.scan(/Version:(\d+)/).flatten.first.to_i
        when :live
          page = Adyen::Admin.get(VERSION_LIVE % code)
          page.search("body p").first.content.scan(/Version:(\d+)/).flatten.first.to_i
        else
          page = Adyen::Admin.get(TEST % code)
          page.search(".data tr td")[2].content.to_i
        end
      end

      def test_url(options = {})
        page = Adyen::Admin.get(TEST % code)
        page = Adyen::Admin.client.submit(page.form.tap do |form|
          #:amount => 199, :currency => :shopper_locale, :country_code, :merchant_reference, :merchant_account, :system, :skip, :one_page
        end)
        Addressable::URI.parse(page.form.action).tap do |uri|
          uri.query_values = page.form.fields.inject({}) { |hash, node|
            hash[node.name] = node.value; hash
          }
        end
      end

      ##########################################

      # http://stackoverflow.com/questions/4360043/using-wwwmechanize-to-download-a-file-to-disk-without-loading-it-all-in-memory
      # Adyen::Admin.client.pluggable_parser.default = Mechanize::FileSaver
      def download
        "#{code}.zip".tap do |filename|
          Adyen::Admin.client.download(DOWNLOAD % code, filename)

          if path
            # create backup of current
            # compile
          end
          # unzip
        end
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

            dir = File.join(File.dirname(path), parent_skin_code)
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

      def parent_skin_code
        "base"
      end

      # http://stackoverflow.com/questions/3420587/ruby-mechanize-multipart-form-with-file-upload-to-a-mediawiki
      def upload
        file = self.compile
        page = Adyen::Admin.get(UPLOAD % code)
        page = Adyen::Admin.client.submit(page.form.tap do |form|
          form.file_uploads.first.file_name = file
        end)
        form = page.form
        page = form.submit(page.form.button_with(:name => 'submit'))
      end

      def publish
        raise ArgumentError unless code

        page = Adyen::Admin.get(PUBLISH % code)
        page = Adyen::Admin.client.submit(page.form.tap do |form|
        end)
      end

      #################################

      def to_s
        self.code
      end

      def ==(skin)
        self.code == skin.code
      end

      protected
      def code=(c)
        @code = c
      end

      def name=(n)
        @name = n
      end

      def self.is_skin_path?(path)
        %w(skin.html.erb inc css js).each do |sub_path|
          return true if File.exists?(File.join(path.to_s, sub_path))
        end
        false
      end
    end
  end
end

