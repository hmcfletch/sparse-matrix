# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "sparse-matrix"
  s.version     = "0.1"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Les Fletcher"]
  s.email       = ["les.fletcher@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Sparse matrix and vector classes for Ruby}
  s.description = %q{Sparse matrix and vector classes for Ruby that can be dropped in place for the built in Matrix and Vector classes}

  s.rubyforge_project = "sparse-matrix"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
