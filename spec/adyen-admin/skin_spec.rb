require "spec_helper"

require "adyen-admin/client"
require "adyen-admin/skin"

module Adyen::Admin
  describe Skin, :vcr  do
    let(:skin_fixtures) { File.expand_path 'spec/fixtures/skins' }
    let(:skin_code) { "7hFAQnmt" }
    let(:skin) { Skin.new(:code => skin_code, :name => "example") }

    describe ".all" do
      it 'returns all local skins' do
        Skin.all.should == Skin.all_local
      end
    end

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
          Skin.all_remote.should == [
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
          Skin.all_local.should == [
            Skin.new(:code => "base"),
            Skin.new(:code => "DV3tf95f"),
            skin,
            Skin.new(:code => "JH0815"),
          ]
        end
      end

      describe ".all" do
        it 'returns the skins' do
          Skin.all.should == [
            skin,
            Skin.new(:code => "Kx9axnRf", :name => "demo"),
            Skin.new(:code => "vQW0fEo8", :name => "test"),
            Skin.new(:code => "base"),
            Skin.new(:code => "DV3tf95f"),
            Skin.new(:code => "JH0815")
          ]
        end

        it 'freezes local skins' do
          Skin.all.last.should be_frozen
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

        context "with skin data file" do
          let(:path) { "#{skin_fixtures}/DV3tf95f" }
          let(:skin) { Skin.new(:path => path) }

          it "sets name" do
            skin.name.should == "DV3tf95f"
          end

          it "sets code" do
            skin.code.should == "customCode"
          end

          it "sets version_live" do
            skin.path.should == "#{skin_fixtures}/DV3tf95f"
          end

          it "sets version" do
            skin.version.should == 12
          end

          it "sets version_test" do
            skin.version_test.should == 3
          end

          it "sets version_live" do
            skin.version_live.should == 2
          end

          context "init by code" do
            let(:skin) { Skin.new(:name => "DV3tf95f", :code => "customCode") }

            it "sets name" do
              skin.name.should == "DV3tf95f"
            end

            it "sets version_live" do
              skin.path.should == "#{skin_fixtures}/DV3tf95f"
            end
          end
        end
      end

      describe "#update"  do
        let(:path) { "#{skin_fixtures}/example-7hFAQnmt" }

        before do
          skin.path = path
        end

        after do
          `rm -f #{path}/skin.yml`
        end

        it "create skin.yml file" do
          expect do
            skin.update
          end.to change { File.exists?("#{path}/skin.yml") }
        end

        context "local skin" do
          it "returns version" do
            skin.version.should be_nil
          end

          it "returns version" do
            skin.version_live.should be_nil
          end

          it "returns version" do
            skin.version_test.should  be_nil
          end
        end

        context "remote fails" do
          before do
            Adyen::Admin.stub(:get).and_raise(StandardError)
          end

          it "returns version" do
            skin.update
            skin.version.should be_nil
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

        it "is a zipfile" do
          Zip::ZipFile.open(skin.download) do |zipfile|
            zipfile.find_entry(File.join(skin_code, "inc", "cheader.txt")).should be_true
          end
        end
      end

      describe "#decompile"  do
        let(:skin_code) { "DV3tf95f" }
        let(:skin) { Skin.new(:path => "#{skin_fixtures}/#{skin_code}") }

        after do
          `rm -rf #{zip_filename}`
        end

        context "existing skin" do
          let(:backup_filename) { File.join(skin.path, '.backup.zip') }
          let!(:zip_filename) { skin.compress(nil) }

          before do
            `cp -r #{skin_fixtures}/#{skin_code} #{skin_fixtures}/_backup`
          end

          after do
            `rm -rf #{backup_filename} #{skin_fixtures}/#{skin_code}`
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

        context "new remote skin" do
          let(:skin) { Skin.new(:name => "test", :code => "vQW0fEo8") }
          let!(:zip_filename) { skin.download }

          after do
            `rm -rf #{skin.path}`
          end

          it "downloads and decompiles skin" do
            expect do
              skin.decompile(zip_filename)
            end.to change { skin.path }
          end
        end
      end

      describe "#compile" do
        let(:skin_code) { "JH0815" }
        let(:skin) { Skin.new(:path => File.join(skin_fixtures, skin_code)) }
        let(:output) { File.read File.join('spec/fixtures', 'output.html') }

        before do
          skin.compile(output)
        end

        after do
          FileUtils.rm_rf( skin.path + '/inc')
        end

        it 'writes cheader' do
          File.read( skin.path + '/inc/cheader.txt').should == "<!-- ### inc/cheader_[locale].txt or inc/cheader.txt (fallback) ### -->"
        end

        it 'writes pmheader' do
          File.read( skin.path + '/inc/pmheader.txt').should == "<!-- ### inc/pmheader_[locale].txt or inc/pmheader.txt (fallback) ### -->"
        end

        it 'writes pmfooter' do
          File.read( skin.path + '/inc/pmfooter.txt').should == "<!-- ### inc/pmfooter_[locale].txt or inc/pmfooter.txt (fallback) ### -->\n\n  <!-- ### inc/customfields_[locale].txt or inc/customfields.txt (fallback) ### -->"
        end

        it 'writes cfooter' do
          File.read( skin.path + '/inc/cfooter.txt').should == "<!-- ### inc/cfooter_[locale].txt or inc/cfooter.txt (fallback) ### -->"
        end
      end

      describe "#compress" do
        let(:skin_code) { "DV3tf95f" }
        let(:path) { "#{skin_fixtures}/#{skin_code}" }
        let(:skin) { Skin.new(:path => path) }
        let(:zip_filename) { skin.compress }

        def zip_contains(file)
          Zip::ZipFile.open(zip_filename) do |zipfile|
            return true if zipfile.find_entry(File.join(skin.code, file))
          end
          false
        end

        after do
          `rm -f #{skin.code}.zip`
        end

        context "no skin.yml" do
          before do
            `mv #{path}/skin.yml #{path}/skin2.yml`
          end

          after do
            `mv #{path}/skin2.yml #{path}/skin.yml`
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
            zip_contains("skin2.yml").should_not be_true
          end

          it "excludes skin file" do
            zip_contains("skin.html.erb").should_not be_true
          end
        end

        context "with sub subfolders" do
          before do
            `mkdir #{path}/css/vendor`
            `touch #{path}/css/vendor/test.css`
          end

          after do
            `rm -rf #{path}/css/vendor`
          end

          it "throws exception" do
            expect do
              skin.compress
            end.to raise_error
          end
        end

        context "no exlusion" do
          let(:zip_filename) { skin.compress(nil) }

          it "excludes meta file" do
            zip_contains("skin.yml").should be_true
          end

          it "excludes skin file" do
            zip_contains("skin.html.erb").should be_true
          end
        end

        context "with parent_skin_code" do
          let(:skin_code) { "JH0815" }

          before do
            skin.stub(:parent_skin_code).and_return("example-7hFAQnmt")
          end

          it "excludes meta file" do
            zip_contains("img/bg.gif").should be_true
          end
        end
      end

      describe "#upload" do
        let(:path) { "#{skin_fixtures}/example-7hFAQnmt" }

        after do
          `rm -f #{skin_code}.zip`
          `rm -f #{path}/skin.yml`
        end

        context "valid set" do
          before do
            skin.path = path
          end

          it "increases version" do
            expect do
              skin.upload
            end.to change { skin.send(:remote_version) }.by(1)
          end

          it "updates skin data" do
            skin.should_receive(:update)

            skin.upload
          end
        end
      end

      describe "#remote_version" do
        let(:skin) { Skin.new(:code => "Kx9axnRf", :name => "demo") }
        let(:version) { 17 }

        it "returns uploaded value" do
          skin.send(:remote_version).should == version
        end

        it "returns test value" do
          skin.send(:remote_version, :test).should == version
        end

        it "returns live value" do
          skin.send(:remote_version, :live).should == 0
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
