# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "zactor/version"

Gem::Specification.new do |s|
  s.name = %q{zactor}
  s.version = Zactor::VERSION
  s.summary = "Zactor"
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Andrew Rudenko"]
  s.date = Time.now.strftime('%Y-%m-%d')
  s.description = %q{Zactor}
  s.email = %q{ceo@prepor.ru}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency('ffi', ["> 0.1"])
  s.add_dependency('ruby-interface', ["> 0"])
  s.add_dependency('ffi-rzmq', ["> 0.1"])
  s.add_dependency('em-zeromq', ["> 0.1"])
  s.add_dependency('bson', ["> 0.1"])
  s.add_dependency('bson_ext', ["> 0.1"])
  s.add_dependency('activesupport', ["> 0.1"])
  s.add_dependency('uuid', ["> 0.1"])
end

