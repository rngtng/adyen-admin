module Adyen
  module Admin
    class Skin
      UPLOAD = "https://ca-test.adyen.com/ca/ca/skin/uploadskin.shtml?skinCode=%s"
      DOWNLOAD = "https://ca-test.adyen.com/ca/ca/skin/downloadskin.shtml?skinCode=%s"

      attr_accessor :code, :description

      def initialize(code, description)
        @code = code
        @description = description
      end

      def download
      end

      def upload(file)
      end

      def version
      end

      def to_s
        "#{@code} - #{@description}"
      end

      def ==(skin)
        @code == skin.code
      end

    end
  end
end

