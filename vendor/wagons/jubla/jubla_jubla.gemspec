$:.push File.expand_path("../lib", __FILE__)

# Maintain your wagon's version:
require "jubla_jubla/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "jubla_jubla"
  s.version     = JublaJubla::VERSION
  s.authors     = ["Pascal Zumkehr"]
  s.email       = ["zumkehr@puzzle.ch"]
  #s.homepage    = "TODO"
  s.summary     = "Jubla"
  s.description = "TODO: description"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["Rakefile"]
  s.test_files = Dir["test/**/*"]

end
