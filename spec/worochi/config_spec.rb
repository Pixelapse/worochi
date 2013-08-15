require 'spec_helper'

class Worochi
  describe Config do
    describe '.services' do
      it 'returns an Array of services' do
        expect(Config.services.class).to be(Array)
        expect(Config.services.first.class).to be(Symbol)
      end
    end

    describe '.service_display_name' do
      it 'returns display name given an ID' do
        expect(Config.service_display_name(1)).to eq('GitHub')
      end
      it 'accepts display name given a name' do
        expect(Config.service_display_name(:dropbox)).to eq('Dropbox')
      end
      it 'returns nil when not found' do
        expect(Config.service_display_name(:zzzzzz)).to eq(nil)
        expect(Config.service_display_name(-1111)).to eq(nil)
      end
    end

    describe '.service_id' do
      it 'returns the service ID given name' do
        expect(Config.service_id(:dropbox)).to eq(2)
      end
      it 'returns nil when not found' do
        expect(Config.service_id(:zzzzzzz)).to eq(nil)
      end
    end

    describe '.service_name' do
      it 'returns the service name given ID' do
        expect(Config.service_name(1)).to eq(:github)
      end
      it 'returns nil when not found' do
        expect(Config.service_name(-1111)).to eq(nil)
      end
    end

    describe '.service_opts' do
      it 'retrieves the service options' do
        opts = Config.service_opts(:dropbox)
        expect(opts).to include(:service)
      end
      it 'raises error on nil' do
        expect{Config.service_opts(nil)}.to raise_error Error
        expect{Config.service_opts(:zzzzz)}.to raise_error Error
        Config.instance_variable_set(:@options, nil)
        expect{Config.service_opts(:dropbox)}.to raise_error Error
        Worochi.init
      end
    end
  end
end