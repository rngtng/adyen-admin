require "spec_helper"

require "adyen-admin/client"

describe Adyen::Admin::Skin, :vcr  do
  let(:skin_code) { "Kx9axnRf" }
  let(:skin) { Adyen::Admin.skins.select { |skin| skin.code == skin_code }.first }

  before do
    Adyen::Admin.login("SoundCloud", "Test", "12312311")
  end

  describe "#download"  do
  end

  describe "#upload" do
  end

  describe "#version" do
    it "returns uploaded value" do
      skin.version.should == "2"
    end

    it "returns test value" do
      skin.version(:test).should == "2"
    end

    it "returns live value" do
      skin.version(:live).should == "0"
    end
  end

  describe "#test_url" do
    it "returns url to test" do
      skin.test_url.to_s.should include("https://test.adyen.com/hpp/select.shtml")
    end
    #todo test with options
  end

end
