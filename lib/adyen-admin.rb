# Copyright (c) 2012, SoundCloud Ltd., Tobias Bielohlawek

require 'adyen-admin/client'
require 'adyen-admin/skin'

module Adyen
  module Admin
    extend Adyen::Admin::Client

    class AuthenticationError < StandardError; end

    def skin_dir
      "."
    end
    module_function :skin_dir
  end
end
