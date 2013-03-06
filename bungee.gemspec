# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bungee/version'

Gem::Specification.new do |gem|
  gem.name          = "bungee"
  gem.version       = Bungee::VERSION
  gem.authors       = ["Jack Chen (chendo)"]
  gem.email         = ["gems+bungee#chen.do"]
  gem.description   = %q{Performs hot backups and restores of Elasticsearch indexes}
  gem.summary       = %q{Performs hot backups and restores of Elasticsearch indexes}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency('rye', '~> 0.9.2')
  gem.add_dependency('commander', '~> 4.1.3')
end
