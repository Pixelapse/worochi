require 'simplecov'
require 'coveralls'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start

require 'worochi'
require 'filemagic'
require 'awesome_print'
require 'digest'
require 'vcr'
require 'webmock/rspec'

Dir["./spec/support/**/*.rb"].sort.each { |f| require f }

VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :webmock
  c.configure_rspec_metadata!
  c.default_cassette_options = {
    record: :once
  }
end

# Service manifest
test_token_prefix = {
  google_drive: 'GOOGLE',
  dropbox: 'DROPBOX',
  github: 'GITHUB'
}

# Removes sensitive keys from recordings
VCR.configure do |c|
  c.filter_sensitive_data('<AWS_KEY>') { ENV['AWS_SECRET_ACCESS_KEY'] }
  c.filter_sensitive_data('<AWS_ID>') { ENV['AWS_ACCESS_KEY_ID'] }

  test_token_prefix.each do |service, prefix|
    c.filter_sensitive_data("<#{prefix}_TOKEN>") { ENV["#{prefix}_TEST_TOKEN"] }
    c.filter_sensitive_data("<#{prefix}_ID>") { ENV["#{prefix}_ID"] }
    c.filter_sensitive_data("<#{prefix}_SECRET>") { ENV["#{prefix}_SECRET"] }
  end
end

RSpec.configure do |c|
  c.color_enabled = true
  c.tty = true
  c.formatter = :documentation
  c.treat_symbols_as_metadata_keys_with_true_values = true # needed for vcr
  c.include TestFiles

  original_stderr = $stderr
  original_stdout = $stdout
  c.before(:all) do
    Worochi::Config.silent = true
  end
  c.after(:all) do 
    Worochi::Config.silent = false
  end

  # Exclude tests involving AWS if secret key is not set
  if ENV['AWS_SECRET_ACCESS_KEY'].nil?
    c.filter_run_excluding :aws
  end

  test_token_prefix.each do |service, prefix|
    if ENV["#{prefix}_TEST_TOKEN"].nil?
      c.filter_run_excluding service
      service_name = Worochi::Config.service_display_name(service)
      puts "#{prefix}_TEST_TOKEN not found. Skipping #{service_name} tests."
    end
  end 
end
