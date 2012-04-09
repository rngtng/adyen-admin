require "spec_helper"

describe Adyen::Admin do
  let(:client) { Adyen::Admin.new("SoundCloud", "Test", "12312311") }

  describe "#login" do #, :vcr
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
end
