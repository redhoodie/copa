$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "copa/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "copa"
  s.version     = Copa::VERSION
  s.authors     = ["Michael Brown"]
  s.email       = ["redhoodie@gmail.com"]
  s.homepage    = "https://github.com/redhoodie/copa"
  s.summary     = "Church Online Platform API helper"
  s.description = "A rudimentary ruby gem to help with using the Church Online Platform API."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails"

  s.add_development_dependency "sqlite3"
end
