require 'helper'

describe Worochi::Config do
  describe '.services' do
    it 'returns an Array of services' do
      expect(Worochi::Config.services.class).to be(Array)
      expect(Worochi::Config.services.first.class).to be(Symbol)
    end
  end

  describe '.service_display_name' do
    it 'returns display name given an ID' do
      expect(Worochi::Config.service_display_name(1)).to eq('GitHub')
    end
    it 'accepts display name given a name' do
      expect(Worochi::Config.service_display_name(:dropbox)).to eq('Dropbox')
    end
    it 'returns nil when not found' do
      expect(Worochi::Config.service_display_name(:zzzzzz)).to eq(nil)
      expect(Worochi::Config.service_display_name(-1111)).to eq(nil)
    end
  end

  describe '.service_id' do
    it 'returns the service ID given name' do
      expect(Worochi::Config.service_id(:dropbox)).to eq(2)
    end
    it 'returns nil when not found' do
      expect(Worochi::Config.service_id(:zzzzzzz)).to eq(nil)
    end
  end

  describe '.service_name' do
    it 'returns the service name given ID' do
      expect(Worochi::Config.service_name(1)).to eq(:github)
    end
    it 'returns nil when not found' do
      expect(Worochi::Config.service_name(-1111)).to eq(nil)
    end
  end
end