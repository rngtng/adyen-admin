require 'tempfile'
require 'zip/zip'
require 'yaml'

module Adyen
  module Admin
    class Skin
      UPLOAD       = "https://ca-test.adyen.com/ca/ca/skin/uploadskin.shtml?skinCode=%s"
      DOWNLOAD     = "https://ca-test.adyen.com/ca/ca/skin/downloadskinsubmit.shtml?downloadSkin=Download&skinCode=%s"
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

        self.path ||= File.expand_path File.join(Skin.default_path, [name,code].compact.join("-"))

        raise ArgumentError, "No Code given" unless code
      end

      def self.default_path
        @default_path || "."
      end

      def self.default_path=(path)
        @default_path = path
      end

      # union remote and local skins. Local skins are frozen to
      # indicate no availble remote counter part which avoid update
      def self.all
        @all ||= {}.tap do |hash|
          if Adyen::Admin.authenticated?
            self.all_remote.each do |skin|
              hash[skin.code] = skin unless hash[skin.code]
            end
          end
          self.all_local.each do |skin|
            hash[skin.code] = skin unless hash[skin.code]
          end
        end.values
      end

      # fetch all remote skins
      def self.all_remote
        page = Adyen::Admin.get(SKINS)
        page.search(".data tbody tr").map do |node|
          Skin.new({
            :code => node.search("a")[0].content.strip,
            :name => node.search("td")[1].content.strip,
          })
        end
      end

      # fetch all local skins
      def self.all_local
        Dir[File.join(default_path.to_s, "*")].map do |path|
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
        @all = nil
      end

      ##################################

      def path=(new_path)
        if Skin.is_skin_path?(new_path)
          @path = new_path
          if !skin_data.empty?
            self.code = skin_data[:code]
            self.name = skin_data[:name]
          else
            new_code, *new_name = File.basename(new_path).split("-").reverse
            self.code ||= new_code
            self.name ||= new_name.reverse.join("-")
            raise ArgumentError if self.code && self.code != new_code
          end
        end
      end

      def skin_data(force_update = false)
        update if force_update
        @skin_data ||= YAML.load_file(skin_data_file) rescue {}
      end

      def uploaded_at
        skin_data[:uploaded_at]
      end

      def version
        skin_data[:version]
      end

      def version_live
        skin_data[:version_live]
      end

      def version_test
        skin_data[:version_test]
      end

      ##########################################

      def update
        @skin_data = {
          :name => name,
          :code => code,
          :uploaded_at => Time.now,
          :version => remote_version,
          :version_live => remote_version(:live),
          :version_test => remote_version(:test),
        }
        File.open(skin_data_file, "w") do |file|
          file.write @skin_data.to_yaml
        end
      end

      # http://stackoverflow.com/questions/4360043/using-wwwmechanize-to-download-a-file-to-disk-without-loading-it-all-in-memory
      # Adyen::Admin.client.pluggable_parser.default = Mechanize::FileSaver
      def download
        "#{code}.zip".tap do |filename|
          Adyen::Admin.client.download(DOWNLOAD % code, filename)
        end
      end

      def decompile(filename, backup = true)
        # create backup of current, include any files
        if self.path
          if backup
            compress(/(zip|lock)$/, ".backup.zip")
          end
        else
          backup = false
          decompile_path = File.join(Skin.default_path, [name,code].compact.join("-"))
          `mkdir -p #{decompile_path}`
        end

        Zip::ZipFile.open(filename) do |zip_file|
          zip_file.each do |file|
            f_path = File.join(self.path || decompile_path, file.name.gsub("#{code}/", ""))
            FileUtils.mkdir_p(File.dirname(f_path))
            if File.directory?(f_path)
              `mkdir -p #{f_path}`
            else
              `rm -f #{f_path}`
              zip_file.extract(file, f_path)
            end
          end
        end
        self.path ||= decompile_path

        if backup
          `mv .backup.zip #{File.join(self.path, ".backup.zip")}`
        end
      end

      def compile(output, pattern = /<!-- ### inc\/([a-z]+) -->(.+?)<!-- ### -->/m)
        raise ArgumentError, "No Path given" unless path

        output.scan(pattern) do |name, content|
          file = File.join(path, "inc/#{name}.txt")
          `mkdir -p #{File.dirname(file)}`
          File.open(file, "w") do |f|
            f.write content.strip
          end
        end
      end

      def compress(exclude = /(yml|zip|erb)$/, outfile = "#{code}.zip")
        raise ArgumentError, "No Path given" unless path

        outfile.tap do |filename|
          `rm -f #{filename}`
          Zip::ZipFile.open(filename, Zip::ZipFile::CREATE) do |zip_file|
            Dir["#{path}/**/**"].each do |file|
              next if file =~ exclude
              zip_file.add(file.sub(path, code), file)
            end

            dir = File.join(File.dirname(path), parent_skin_code)
            Dir["#{dir}/**/**"].each do |file|
              begin
                next if file =~ exclude
                zip_file.add(file.sub(dir, code), file)
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
        file = self.compress
        page = Adyen::Admin.get(UPLOAD % code)
        page = Adyen::Admin.client.submit(page.form.tap do |form|
          form.file_uploads.first.file_name = file
        end)
        form = page.form
        page = form.submit(page.form.button_with(:name => 'submit'))
        update
      end

      def publish
        page = Adyen::Admin.get(PUBLISH % code)
        page = Adyen::Admin.client.submit(page.form.tap do |form|
        end)
      end

      #################################

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

      def skin_data_file
        File.join(path, 'skin.yml')
      end

      def self.is_skin_path?(path)
        %w(skin.html.erb skin.yml inc css js).each do |sub_path|
          return true if File.exists?(File.join(path.to_s, sub_path))
        end
        false
      end

      ##################################

      def remote_version(scope = nil)
        case scope
        when :test
          @version_local ||= begin
            page = Adyen::Admin.get(VERSION_TEST % code)
            page.search("body p").first.content.scan(/Version:(\d+)/).flatten.first.to_i
          end
        when :live
          page = Adyen::Admin.get(VERSION_LIVE % code)
          page.search("body p").first.content.scan(/Version:(\d+)/).flatten.first.to_i
        else
          page = Adyen::Admin.get(TEST % code)
          page.search(".data tr td")[2].content.to_i
        end
      rescue
        nil
      end
    end
  end
end

