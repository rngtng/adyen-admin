# Copyright (c) 2013, SoundCloud Ltd., Tobias Bielohlawek

require 'adyen-admin/client'
require 'adyen-admin/skin'

module Adyen
  module Admin
    extend Adyen::Admin::Client

    class AuthenticationError < StandardError; end

  end
end
