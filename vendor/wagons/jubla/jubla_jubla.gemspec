$:.push File.expand_path("../lib", __FILE__)

# Maintain your wagon's version:
require "jubla_jubla/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "jubla_jubla"
  s.version     = JublaJubla::VERSION
  s.authors     = ["Pascal Zumkehr"]
  s.email       = ["zumkehr@puzzle.ch"]
  s.summary     = "Jubla organization specific features"
  s.description = "Jubla organization specific features"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["Rakefile"]
  s.test_files = Dir["spec/**/*"]

end
