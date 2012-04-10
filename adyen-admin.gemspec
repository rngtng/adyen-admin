# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "adyen-admin"
  s.version     = File.read("VERSION")
  s.authors     = ["Tobias Bielohlawek"]
  s.email       = ["tobi@soundcloud.com"]
  s.homepage    = "https://github.com/rngtng/adyen-admin"
  s.summary     = %q{Adyen Admin Skin API and Command line tool}
  s.description = %q{A little Gem to make your life easier when dealing with Adyen skins}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  %w(mechanize rubyzip).each do |gem|
    s.add_runtime_dependency *gem.split(' ')
  end

  %w(rake rspec vcr webmock debugger).each do |gem|
    s.add_development_dependency *gem.split(' ')
  end
end
