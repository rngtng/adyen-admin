require "spec_helper"

require "adyen-admin/client"

describe Adyen::Admin::Client, :vcr  do
  let(:login) { Adyen::Admin.login("SoundCloud", "skinadmin", "12312311") }

  before do
    Adyen::Admin.client.cookie_jar.clear!
  end

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

  describe "#get" do
    it 'raises authenticated error when not logged in' do
      expect do
        Adyen::Admin.get(Adyen::Admin::Skin::SKINS)
      end.to raise_error Adyen::Admin::AuthenticationError
    end

    it 'sets authenticated to false on error' do
      Adyen::Admin.instance_variable_set(:@authenticated, true)

      expect do
        Adyen::Admin.get(Adyen::Admin::Skin::SKINS) rescue nil
      end.to change { Adyen::Admin.authenticated? }.from(true).to(false)
    end
  end
end
