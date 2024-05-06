# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)

require "decidim/ej/version"

Gem::Specification.new do |s|
  s.version = Decidim::Ej.version
  s.authors = ["David Carlos de Araújo Silva"]
  s.email = ["ddavidcarlos1392@gmail.com"]
  s.license = "AGPL-3.0"
  s.homepage = "https://decidim.org"
  s.metadata = {
    "bug_tracker_uri" => "https://github.com/decidim/decidim/issues",
    "documentation_uri" => "https://docs.decidim.org/",
    "funding_uri" => "https://opencollective.com/decidim",
    "homepage_uri" => "https://decidim.org",
    "source_code_uri" => "https://github.com/decidim/decidim"
  }
  s.required_ruby_version = ">= 3.0.7"

  s.name = "decidim-ej"
  s.summary = "Pushing Together integration module."
  s.description = "Extends Decidim adding Pushing Together opinion research capabilities."

  s.files = Dir["{app,config,lib}/**/*", "LICENSE-AGPLv3.txt", "Rakefile", "README.md"]

  s.add_dependency "decidim-core", Decidim::Ej.version
  s.add_dependency "httparty"
end
