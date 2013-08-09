require 'worochi'
require 'awesome_print'
require 'webmock/rspec'
require 'vcr'

Dir["./spec/support/**/*.rb"].sort.each {|f| require f}

VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :webmock
  c.configure_rspec_metadata!
  c.default_cassette_options = {
    record: :new_episodes
  }
end

RSpec.configure do |c|
  c.color_enabled = true
  c.tty = true
  c.formatter = :documentation
  c.treat_symbols_as_metadata_keys_with_true_values = true # needed for vcr
end

def github_token
  ENV['GITHUB_TEST_TOKEN']
end