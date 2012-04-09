# Copyright (c) 2012, SoundCloud Ltd., Tobias Bielohlawek

require 'mechanize'
require 'debugger'

module Adyen
  class Admin
    LOGIN       = "https://ca-test.adyen.com/ca/ca/login.shtml"
    DASHBOARD   = "https://ca-test.adyen.com/ca/ca/overview/default.shtml"

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

    private
    def agent
      @agent ||= Mechanize.new
    end
  end
end
