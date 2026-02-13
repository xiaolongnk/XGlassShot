#!/usr/bin/env ruby
# Writes support_url.txt, privacy_url.txt, and copyright.txt into each locale folder.
# Prefers ENV from ~/.zshrc: FASTLANE_SUPPORT_URL, FASTLANE_PRIVACY_URL, FASTLANE_COPYRIGHT.
# If only FASTLANE_SUPPORT_URL is set, it is used for both support and privacy.
# Falls back to fastlane/metadata/APP_STORE_CONFIG.txt.
# Run from repo root: ruby fastlane/scripts/sync_metadata_urls.rb

config_path = File.join(__dir__, "..", "metadata", "APP_STORE_CONFIG.txt")
metadata_dir = File.join(__dir__, "..", "metadata")

config = {}
if File.exist?(config_path)
  File.foreach(config_path) do |line|
    line = line.strip
    next if line.empty? || line.start_with?("#")
    k, v = line.split("=", 2)
    config[k.strip] = v.to_s.strip if k && v
  end
end

support_url = ENV["FASTLANE_SUPPORT_URL"].to_s.strip
privacy_url  = ENV["FASTLANE_PRIVACY_URL"].to_s.strip
support_url = privacy_url if support_url.empty? && !privacy_url.empty?
privacy_url = support_url if privacy_url.empty? && !support_url.empty?
support_url = config["SUPPORT_AND_PRIVACY_URL"] if support_url.empty?
privacy_url  = support_url if privacy_url.empty?

url = support_url.empty? ? (config["SUPPORT_AND_PRIVACY_URL"] || "https://example.com") : support_url
privacy_url = privacy_url.empty? ? url : privacy_url
copyright = (ENV["FASTLANE_COPYRIGHT"].to_s.strip.empty? ? nil : ENV["FASTLANE_COPYRIGHT"]) || config["COPYRIGHT"] || "Copyright © 2024. All rights reserved."

Dir.each_child(metadata_dir) do |name|
  next unless File.directory?(File.join(metadata_dir, name))
  next if name.start_with?(".")
  locale_dir = File.join(metadata_dir, name)
  [["support_url.txt", url], ["privacy_url.txt", privacy_url], ["copyright.txt", copyright]].each do |file, content|
    File.write(File.join(locale_dir, file), content + "\n")
  end
  puts "Updated #{name}/ (support_url, privacy_url, copyright)"
end
