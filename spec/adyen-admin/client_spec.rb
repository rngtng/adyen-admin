require "spec_helper"

require "adyen-admin/client"

describe Adyen::Admin::Client, :vcr  do
  let(:login) { Adyen::Admin.login("SoundCloud", "skinadmin", "12312311") }

  describe "#login" do
    it 'passes with correct username + password' do
      expect do
        login
      end.to_not raise_error
    end

    it 'fails on wrong username + password' do
      expect do
        Adyen::Admin.login("Tobi", "fake", "wrong")
      end
    end
  end
end
