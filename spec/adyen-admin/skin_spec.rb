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

        it 'sets local path' do
          Adyen::Admin::Skin.default_path = skin_fixtures
          Skin.all_remote.first.path.should == "#{skin_fixtures}/example-7hFAQnmt"
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

        it "auto sets name from path" do
          Skin.new(:path => path).name.should == "example"
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

        context "slash in name" do
          let(:path) { "#{skin_fixtures}/example-test-7hFAQnmt" }

          it "sets name" do
            Skin.stub(:is_skin_path?).and_return(true)
            Skin.new(:path => path).name.should == "example-test"
          end
        end
      end

      describe "#download"  do
        let(:zip_filename) { "#{skin.code}.zip" }

        after do
          `rm -rf #{zip_filename}`
        end

        it "gets the file" do
          skin.download
          File.should be_exists(zip_filename)
        end
      end

      describe "#decompile"  do
        let(:skin_code) { "DV3tf95f" }
        let(:skin) { Skin.new(:path => "#{skin_fixtures}/#{skin_code}") }
        let!(:zip_filename) { skin.compile(nil) }
        let(:backup_filename) { File.join(skin.path, '.backup.zip') }

        before do
          `cp -r #{skin_fixtures}/#{skin_code} #{skin_fixtures}/_backup`
        end

        after do
          `rm -rf #{zip_filename} #{backup_filename} #{skin_fixtures}/#{skin_code}`
          `mv #{skin_fixtures}/_backup #{skin_fixtures}/#{skin_code}`
        end

        it "creates backup" do
          skin.decompile(zip_filename)

          File.should be_exists(backup_filename)
        end

        it "unzips files" do
          `rm -rf #{skin.path}`

          expect do
            skin.decompile(zip_filename)
          end.to change { File.exists?(File.join(skin.path, 'inc', 'order_data.txt')) }
        end
      end

      describe "#compile" do
        let(:skin_code) { "DV3tf95f" }
        let(:skin) { Skin.new(:path => "#{skin_fixtures}/#{skin_code}") }
        let(:zip_filename) { skin.compile }

        def zip_contains(file)
          Zip::ZipFile.open(zip_filename) do |zipfile|
            return true if zipfile.find_entry(File.join(skin_code, file))
          end
          false
        end

        after do
          `rm -f #{skin_code}.zip`
        end

        context "without base" do
          before do
            `mv #{skin_fixtures}/base #{skin_fixtures}/base2`
          end

          after do
            `mv #{skin_fixtures}/base2 #{skin_fixtures}/base`
          end

          it "includes screen file" do
            zip_contains("css/screen.css").should be_true
          end

          it "excludes print files" do
            zip_contains("css/print.css").should_not be_true
          end
        end

        it "includes screen file" do
          zip_contains("css/screen.css").should be_true
        end

        it "includes print file" do
          zip_contains("css/print.css").should be_true
        end

        it "excludes meta file" do
          zip_contains("metadata.yml").should_not be_true
        end

        it "excludes skin file" do
          zip_contains("skin.html.erb").should_not be_true
        end

        context "no exlusion" do
          let(:zip_filename) { skin.compile(nil) }

          it "excludes meta file" do
            zip_contains("metadata.yml").should be_true
          end

          it "excludes skin file" do
            zip_contains("skin.html.erb").should be_true
          end
        end
      end

      describe "#upload" do
        after do
          `rm -f #{skin_code}.zip`
        end

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
