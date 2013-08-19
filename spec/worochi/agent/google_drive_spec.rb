require 'spec_helper'

describe Worochi::Agent::GoogleDrive do
  let(:required_keys) { [] }
  let(:client_class) { Google::APIClient::API }

  let(:agent) do
    Worochi::Agent::GoogleDrive.new({
      token: ENV['GOOGLE_DRIVE_TEST_TOKEN'],
      dir: '/Worochi'
    })
  end

  it_should_behave_like 'a service agent'
end