require 'worochi'

describe Worochi do
  describe 'Reset' do
    it "resets the agent list" do
      Worochi.create(:github, 'token')
      Worochi.create(:github, 'token')
      Worochi.create(:github, 'token')
      Worochi.reset
      expect(Worochi.size).to eq(0)
    end
  end

  describe 'Single agent' do
    it 'adds/removes a single agent' do
      a = Worochi.create(:github, 'token')
      expect(Worochi.size).to eq(1)
      Worochi.remove(a)
      expect(Worochi.size).to eq(0)
    end
  end

  describe 'Multiple agents' do
    it 'adds/removes multiple agents' do
      a = Worochi.create(:github, 'token')
      b = Worochi.create(:dropbox, 'token')
      c = Worochi.create(:dropbox, 'token')
      Worochi.remove(b)
      expect(Worochi.size).to eq(2)
      Worochi.remove(c)
      expect(Worochi.size).to eq(1)
      Worochi.remove(a)
      expect(Worochi.size).to eq(0)
      Worochi.remove(c)
      expect(Worochi.size).to eq(0)
    end
  end

  describe 'Remove by service' do
    it 'removes multiple agents by service' do
      Worochi.create(:dropbox, 'token')
      Worochi.create(:github, 'token')
      Worochi.create(:dropbox, 'token')
      Worochi.create(:github, 'token')
      expect(Worochi.size).to eq(4)
      Worochi.remove_service(:dropbox)
      expect(Worochi.size).to eq(2)
      Worochi.reset
      expect(Worochi.size).to eq(0)
    end
  end
end