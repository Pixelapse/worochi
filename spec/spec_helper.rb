require 'simplecov'
require 'coveralls'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start

require 'worochi'
require 'awesome_print'
require 'digest'
require 'vcr'

Dir["./spec/support/**/*.rb"].sort.each { |f| require f }

VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :webmock
  c.configure_rspec_metadata!
  c.default_cassette_options = {
    record: :once
  }
end

# Removes sensitive keys from recordings
VCR.configure do |c|
  c.filter_sensitive_data('<AWS_KEY>') { ENV['AWS_SECRET_ACCESS_KEY'] }
  c.filter_sensitive_data('<AWS_ID>') { ENV['AWS_ACCESS_KEY_ID'] }
  c.filter_sensitive_data('<GITHUB_TOKEN>') { ENV['GITHUB_TEST_TOKEN'] }
  c.filter_sensitive_data('<DROPBOX_TOKEN>') { ENV['DROPBOX_TEST_TOKEN'] }
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
  if !ENV['AWS_SECRET_ACCESS_KEY']
    c.filter_run_excluding :aws
  end
end
