require 'spec_helper'

describe Worochi do
  let(:token) { 'service token' }
  def create_dropbox_agent
    Worochi.create(:dropbox, token)
  end

  def create_github_agent
    Worochi.create(:github, token)
  end

  before do
    Worochi.reset
  end

  describe '.size' do
    it 'returns the number of active agents' do
      expect(Worochi.size).to eq(Worochi.agents.size)
    end
  end

  describe '.list' do
    it 'returns the right agent names' do
      a = create_dropbox_agent
      expect(Worochi.list(false)).to include("0")
      expect(Worochi.list(false)).to include("Dropbox")
      b = create_github_agent
      lines = Worochi.list(false).split("\n")
      expect(lines.first).to include("Dropbox")
      expect(lines.last).to include("1")
      expect(lines.last).to include("GitHub")
    end
  end

  describe '.create' do
    it 'creates a single agent' do
      a = Worochi.create(:github, token)
      expect(a.kind_of?(Worochi::Agent)).to be_true
      expect(Worochi.size).to eq(1)
    end

    it 'creates four agents' do
      4.times do
        a = Worochi.create(:dropbox, token)
        expect(a.kind_of?(Worochi::Agent)).to be_true
      end
      expect(Worochi.size).to eq(4)
    end

    it 'requires service and token' do
      expect { Worochi.create }.to raise_error(ArgumentError)
      expect { Worochi.create(:dropbox) }.to raise_error(ArgumentError)
    end

    it 'symbolizes arguments correctly' do
      a = Worochi.create('dropbox', token, { 'test_opt' => 'hi' })
      expect(a.type).to eq(:dropbox)
      expect(a.options[:test_opt]).to eq('hi')
    end
  end

  describe '.reset' do
    it "removes all agents" do
      5.times { create_github_agent }
      expect(Worochi.size).to eq(5)
      Worochi.reset
      expect(Worochi.size).to eq(0)
    end
  end

  describe '.remove_service' do
    it 'removes multiple agents by service' do
      create_dropbox_agent
      create_github_agent
      create_dropbox_agent
      create_github_agent
      expect(Worochi.size).to eq(4)
      Worochi.remove_service(:dropbox)
      create_dropbox_agent
      expect(Worochi.size).to eq(3)
      Worochi.remove_service(:github)
      expect(Worochi.size).to eq(1)
    end

    it 'removes all agents' do
      4.times { create_dropbox_agent }
      4.times { create_github_agent }
      expect(Worochi.size).to eq(8)
      Worochi.remove_service
      expect(Worochi.size).to eq(0)
    end
  end

  describe '.agents' do
    it 'returns a list of active agents' do
      a = create_dropbox_agent
      b = create_dropbox_agent
      expect(Worochi.agents).to include(a, b)
      expect(Worochi.agents.size).to eq(2)
    end
  end

  describe '.add' do
    it 'adds an agent to the list of active agents' do
      a = create_dropbox_agent
      4.times { create_dropbox_agent }
      expect(Worochi.agents).to include(a)
      Worochi.reset
      expect(Worochi.agents).not_to include(a)
      Worochi.add(a)
      expect(Worochi.agents).to include(a)
    end
  end
end