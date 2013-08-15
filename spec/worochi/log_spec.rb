require 'spec_helper'

class Worochi
  describe Log do
    before do
      Config.silent = false
      @output = StringIO.new
      Log.init(@output)
    end

    after do
      Config.silent = true
      Log.init
    end
    
    describe '.warn' do
      it 'logs warning' do
        Log.warn 'test warn'
        expect(@output.string).to include('test warn')
      end
    end

    describe '.error' do
      it 'logs error' do
        Log.error 'test error'
        expect(@output.string).to include('test error')
      end
    end
  end
end