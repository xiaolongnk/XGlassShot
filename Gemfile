# Gemfile for Fastlane (Mac App Store release)
source "https://rubygems.org"

ruby ">= 3.3.0"

gem "fastlane", "~> 2.241", ">= 2.241.1"

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
