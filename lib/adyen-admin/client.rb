require 'mechanize'

module Adyen
  module Admin
    module Client
      LOGIN       = "https://ca-test.adyen.com/ca/ca/login.shtml"
      DASHBOARD   = "https://ca-test.adyen.com/ca/ca/overview/default.shtml"

      def login(accountname, username, password)
        @authenticated = false
        page = Adyen::Admin.client.get(LOGIN)
        page = Adyen::Admin.client.submit(page.form.tap do |form|
          form.j_account  = accountname
          form.j_username  = username
          form.j_password = password
        end)
        raise "Wrong username + password combination" if page.uri.to_s != DASHBOARD
        @authenticated = true
      end

      def get(url)
        client.get(url).tap do |page|
          if !page.uri.to_s.include?(url)
            @authenticated = false
            raise AuthenticationError
          end
        end
      end

      def client
        @agent ||= Mechanize.new
      end

      def authenticated?
        @authenticated
      end
    end
  end
end

