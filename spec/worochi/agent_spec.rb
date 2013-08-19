require 'spec_helper'

class Worochi
  describe Agent do
    let(:agent) { Agent.new({ service: :github, token: '', dir: '/folder' }) }
    describe '.new' do
      it 'initializes the right child class' do
        expect(agent.class).to be(Agent::Github)
      end
    end

    describe '.full_path' do
      let(:item) { Item.open_single(local.source) }
      it 'accepts relative paths' do
        item.path = 'test'
        expect(agent.send(:full_path, item)).to eq('/folder/test')
      end
      it 'accepts absolute paths' do
        item.path = '/test'
        expect(agent.send(:full_path, item)).to eq('/test')
      end
    end

    describe '#name' do
      it 'returns the display name for the agent' do
        expect(agent.name).to eq('GitHub')
      end
    end
    
    describe '#set_dir' do
      it 'sets the remote directory' do
        agent.set_dir('test/a')
        expect(agent.options.dir).to eq('test/a')
      end
    end

    describe '#remove' do
      it 'removes self from the main agent list' do
        a = Worochi.create(:github, '')
        expect(Worochi.agents).to include(a)
        a.remove
        expect(Worochi.agents).not_to include(a)
      end
    end

  end
end