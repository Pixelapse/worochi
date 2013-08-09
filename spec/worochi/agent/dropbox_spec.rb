require 'helper'

describe Worochi::Agent::Dropbox do
  let(:required_keys) { [:chunk_size, :overwrite] }
  let(:client_class) { DropboxClient }

  let(:agent) do
    Worochi::Agent::Dropbox.new({
      token: ENV['DROPBOX_TEST_TOKEN'],
      dir: '/Dev/test'
    })
  end

  it_should_behave_like 'a service agent'
end