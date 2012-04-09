# Copyright (c) 2012, SoundCloud Ltd., Tobias Bielohlawek

require 'mechanize'
require 'adyen-admin/client'
require 'debugger'

module Adyen
  module Admin

    def login(accountname, username, password)
      @client = Client.new(accountname, username, password)
    end
    module_function :login

  end
end
