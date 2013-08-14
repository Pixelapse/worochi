require 'spec_helper'

class Worochi
  describe Agent do
    let(:agent) { Agent.new({ service: :github, token: '' }) }
    describe '.new' do
      it 'initializes the right child class' do
        expect(agent.class).to be(Agent::Github)
      end
    end

    describe '#name' do
      it 'returns the display name for the agent' do
        expect(agent.name).to eq('GitHub')
      end
    end
  end
end