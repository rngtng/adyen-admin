require "spec_helper"

require "adyen-admin/skin"

describe Adyen::Admin do
  let(:client) { Adyen::Admin.login("SoundCloud", "Test", "12312311") }

  describe "#login", :vcr do
    it 'passes with correct username + password' do
      expect do
        client
      end.to_not raise_error
    end

    it 'fails on wrong username + password' do
      expect do
        Adyen::Admin.new("fake", "wrong")
      end
    end
  end

  describe "#skins", :vcr do
    it 'returns the skins' do
      client.skins.should == [
        Adyen::Admin::Skin.new("7hFAQnmt", "example"),
        Adyen::Admin::Skin.new("Kx9axnRf", "demo")
      ]
    end
  end
end
