require "spec_helper"

require "adyen-admin/client"
require "adyen-admin/skin"

module Adyen::Admin
  describe Skin, :vcr  do
    let(:skin_fixtures) { 'spec/fixtures/skins' }
    let(:skin_code) { "7hFAQnmt" }
    let(:skin) { Skin.new(:code => skin_code, :name => "example") }

    context "authenticated" do
      before(:all) do
        VCR.use_cassette("login") do
          Adyen::Admin.client.cookie_jar.clear!
          Adyen::Admin.login("SoundCloud", "skinadmin", "12312311")
        end
      end

      before do
        Adyen::Admin::Skin.purge_cache
      end

      describe ".all_remote" do
        it 'returns the skins' do
          Skin.all.should == [
            skin,
            Skin.new(:code => "Kx9axnRf", :name => "demo"),
            Skin.new(:code => "vQW0fEo8", :name => "test"),
          ]
        end
      end

      describe ".all_local" do
        it 'returns the skins' do
          Skin.all_local(skin_fixtures).should == [
            Skin.new(:code => "base"),
            Skin.new(:code => "DV3tf95f"),
            skin,
            Skin.new(:code => "JH0815"),
          ]
        end
      end

      describe ".all" do
        it 'returns the skins' do
          Skin.all(skin_fixtures).should == [
            skin,
            Skin.new(:code => "Kx9axnRf", :name => "demo"),
            Skin.new(:code => "vQW0fEo8", :name => "test"),
            Skin.new(:code => "base"),
            Skin.new(:code => "DV3tf95f"),
            Skin.new(:code => "JH0815")
          ]
        end

        it 'freezes local skins' do
          Skin.all(skin_fixtures).last.should be_frozen
        end
      end


      describe ".find" do
        it 'returns the skin' do
          Skin.find(skin_code).should == skin
        end

        it 'returns no skin' do
          Skin.find("dummy code").should == nil
        end
      end

      describe "#new" do
        let(:path) { "#{skin_fixtures}/example-7hFAQnmt" }

        it "sets code attribute" do
          Skin.new(:code => skin_code).code.should == skin_code
        end

        it "sets name attribute" do
          Skin.new(:code => skin_code, :name => "name").name.should == "name"
        end

        it "sets path attribute" do
          Skin.new(:path => path).path.should == path
        end

        it "auto sets code from path" do
          Skin.new(:path => path).code.should == "7hFAQnmt"
        end

        it "raises error on wrong code for path" do
          expect do
            Skin.new(:code => "different", :path => path).path.should == path
          end.to raise_error
        end

        it "raises error on empty code" do
          expect do
            Skin.new
          end.to raise_error
        end
      end

      describe "#download"  do
        let(:zip_filename) { "#{skin.code}.zip"}
        after do
          `rm -rf #{zip_filename}`
        end

        it "gets the file" do
          skin.download
          File.should be_exists(zip_filename)
        end
      end

      describe "#compile" do
        let(:skin_code) { "DV3tf95f" }
        let(:skin) { Skin.new(:path => "#{skin_fixtures}/#{skin_code}") }

        def zip_contains(zip_filename, file)
          Zip::ZipFile.open(zip_filename, 'r') do |zipfile|
            return true if zipfile.find_entry(File.join(skin_code, file))
          end
          false
        end

        context "without base" do
          before do
            `mv #{skin_fixtures}/base #{skin_fixtures}/base2`
          end

          after do
            `mv #{skin_fixtures}/base2 #{skin_fixtures}/base`
          end

          it "includes screen file" do
            zip_contains(skin.compile, "css/screen.css").should be_true
          end

          it "excludes print files" do
            zip_contains(skin.compile, "css/print.css").should_not be_true
          end
        end

        it "includes screen file" do
          zip_contains(skin.compile, "css/screen.css").should be_true
        end

        it "includes print file" do
          zip_contains(skin.compile, "css/print.css").should be_true
        end

        it "excludes meta file" do
          zip_contains(skin.compile, "metadata.yml").should_not be_true
        end

        it "excludes skin file" do
          zip_contains(skin.compile, "skin.html.erb").should_not be_true
        end
      end

      describe "#upload" do
        context "valid set" do
          it "increases version" do
            skin.path = "#{skin_fixtures}/example-7hFAQnmt"

            expect do
              skin.upload
            end.to change { skin.version }.by(1)
          end
        end
      end

      describe "#version" do
        let(:skin) { Skin.new(:code => "Kx9axnRf", :name => "demo") }

        it "returns uploaded value" do
          skin.version.should == 14
        end

        it "returns test value" do
          skin.version(:test).should == 14
        end

        it "returns live value" do
          skin.version(:live).should == 0
        end
      end

      describe "#test_url" do
        it "returns url to test" do
          skin.test_url.to_s.should include("https://test.adyen.com/hpp/select.shtml")
        end
        #todo test with options
      end
    end
  end
end
