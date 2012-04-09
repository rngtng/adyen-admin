require "adyen-admin/skin"

module Adyen
  module Admin
    class Client
      LOGIN       = "https://ca-test.adyen.com/ca/ca/login.shtml"
      DASHBOARD   = "https://ca-test.adyen.com/ca/ca/overview/default.shtml"
      SKINS       = "https://ca-test.adyen.com/ca/ca/skin/skins.shtml"

      def initialize(accountname, username, password)
        login(accountname, username, password)
      end

      def login(accountname, username, password)
        page = agent.get(LOGIN)
        page = agent.submit(page.form.tap do |form|
          form.j_account  = accountname
          form.j_username  = username
          form.j_password = password
        end)
        raise "Wrong username + password combination" if page.uri.to_s != DASHBOARD
      end

      def skins
        page = agent.get(SKINS)
        page.search(".data tbody tr").map do |node|
          skin_code = node.search("a")[0].content.strip
          description = node.search("td")[1].content.strip
          Skin.new(skin_code, description)
        end
      end

      private
      def agent
        @agent ||= Mechanize.new
      end

    end
  end
end

