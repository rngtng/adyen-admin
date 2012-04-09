require "adyen-admin/skin"

module Adyen
  module Admin
    module Client
      LOGIN       = "https://ca-test.adyen.com/ca/ca/login.shtml"
      DASHBOARD   = "https://ca-test.adyen.com/ca/ca/overview/default.shtml"
      SKINS       = "https://ca-test.adyen.com/ca/ca/skin/skins.shtml"

      def login(accountname, username, password)
        page = Adyen::Admin.client.get(LOGIN)
        page = Adyen::Admin.client.submit(page.form.tap do |form|
          form.j_account  = accountname
          form.j_username  = username
          form.j_password = password
        end)
        raise "Wrong username + password combination" if page.uri.to_s != DASHBOARD
      end

      def skins
        page = Adyen::Admin.client.get(SKINS)
        page.search(".data tbody tr").map do |node|
          skin_code = node.search("a")[0].content.strip
          description = node.search("td")[1].content.strip
          Skin.new(skin_code, description)
        end
      end

      def client
        @agent ||= Mechanize.new
      end

    end
  end
end

