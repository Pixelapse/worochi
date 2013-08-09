require 'helper'

describe Worochi::Agent::Github do
  let(:required_keys) { [:repo, :source, :target, :block_size, :commit_msg] }
  let(:client_class) { Octokit::Client }

  let(:agent) do
    Worochi::Agent::Github.new({
      token: ENV['GITHUB_TEST_TOKEN'],
      repo: 'darkmirage/test',
      source: 'master',
      target: 'worochi'
    })
  end

  it_should_behave_like 'a service agent'
end