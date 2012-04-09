require "spec_helper"

require "adyen-admin/client"
require "adyen-admin/skin"

describe Adyen::Admin::Client, :vcr  do
  let(:login) { Adyen::Admin.login("SoundCloud", "Test", "12312311") }

  describe "#login" do
    it 'passes with correct username + password' do
      expect do
        login
      end.to_not raise_error
    end

    it 'fails on wrong username + password' do
      expect do
        Adyen::Admin.login("Test", "fake", "wrong")
      end
    end
  end

  describe "#skins" do
    before do
      login
    end

    it 'returns the skins' do
      Adyen::Admin.skins.should == [
        Adyen::Admin::Skin.new("7hFAQnmt", "example"),
        Adyen::Admin::Skin.new("Kx9axnRf", "demo")
      ]
    end
  end
end
