require 'helper'

describe Worochi::Agent::Github do
  let(:agent) do
    Worochi::Agent::Github.new({
      token: github_token,
      repo: 'darkmirage/test',
      source: 'master',
      target: 'worochi'
    })
  end

  it_should_behave_like 'a service agent'

  describe '#default_options' do
    it 'has the required options' do
      [:repo, :source, :target, :block_size, :commit_msg].each do |key|
        expect(agent.default_options.include?(key)).to be_true
      end
    end
  end

  describe '#init_client' do
    it 'returns the client' do
      client = agent.init_client
      expect(client.class).to eq(Octokit::Client)
    end
  end

end