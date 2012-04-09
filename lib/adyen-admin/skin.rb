module Adyen
  module Admin
    class Skin
      UPLOAD   = "https://ca-test.adyen.com/ca/ca/skin/uploadskin.shtml?skinCode=%s"
      DOWNLOAD = "https://ca-test.adyen.com/ca/ca/skin/downloadskin.shtml?skinCode=%s"
      TEST     = "https://ca-test.adyen.com/ca/ca/skin/testpayment.shtml?skinCode=%s"

      VERSION_TEST = "https://test.adyen.com/hpp/version.shtml?skinCode=%s"
      VERSION_LIVE = "https://live.adyen.com/hpp/version.shtml?skinCode=%s"
      PUBLISH = "https://ca-test.adyen.com/ca/ca/skin/publishskin.shtml?skinCode=%s"

      attr_accessor :code, :description

      def initialize(code, description)
        @code = code
        @description = description
      end

      def download
        Adyen::Admin.client.pluggable_parser.default = Mechanize::Download
        Adyen::Admin.client.agent.get(DOWNLOAD % code).save(zip_filename)
      end

      def upload(file)
        page = Adyen::Admin.client.get(UPLOAD % code)
        page = Adyen::Admin.client.submit(page.form.tap do |form|
          form.file_uploads.first.file_name = file
        end)
        page = agent.submit(page.form.tap do |form|
          form.file_uploads.first.file_name = file
        end)
      end

      def publish
        page = Adyen::Admin.client.get(PUBLISH % code)
        page = Adyen::Admin.client.submit(page.form.tap do |form|
        end)
      end

      def generate
        #cp -rf base
        #cp -rf code
        #zip
      end

      def version(scope = :uploaded)
        case scope
        when :test
          page = Adyen::Admin.client.get(VERSION_TEST % code)
          page.search("body p").first.content.scan(/Version:(\d)/).flatten.first
        when :live
          page = Adyen::Admin.client.get(VERSION_LIVE % code)
          page.search("body p").first.content.scan(/Version:(\d)/).flatten.first
        else
          page = Adyen::Admin.client.get(TEST % code)
          page.search(".data tr td")[2].content
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
        "#{@description}-#{@code}.zip"
      end

      def ==(skin)
        @code == skin.code
      end

    end
  end
end

