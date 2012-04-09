# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "adyen-admin/version"

Gem::Specification.new do |s|
  s.name        = "adyen-admin"
  s.version     = Adyen::Admin::VERSION
  s.authors     = ["Tobias Bielohlawek"]
  s.email       = ["tobi@soundcloud.com"]
  s.homepage    = ""
  s.summary     = %q{TODO: Write a gem summary}
  s.description = %q{TODO: Write a gem description}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  %w(mechanize).each do |gem|
    s.add_runtime_dependency *gem.split(' ')
  end

  %w(rake rspec vcr webmock debugger).each do |gem|
    s.add_development_dependency *gem.split(' ')
  end
end
