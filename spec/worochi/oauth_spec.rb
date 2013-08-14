require 'spec_helper'

describe Worochi::OAuth do
  let(:redirect_uri) { 'http://127.0.0.1:3000' }
  let(:auth) { Worochi::OAuth.new(:github, redirect_uri) }
  describe '.new' do
    it 'initializes the options correctly' do
      expect(auth.options.site).to eq('https://github.com')
      expect(auth.client.class).to be(OAuth2::Client)
    end
  end

  describe '#flow_start' do
    it 'returns the URL to begin authorization' do
      url = auth.flow_start
      expect(url).to include("scope=#{auth.send(:scope)}")
      expect(url).to include(auth.options.site)
      expect(url).to include(auth.options.authorize_url)
    end

    it 'supports state' do
      state = SecureRandom.hex
      url = auth.flow_start(state)
      expect(url).to include("state=#{state}")
    end
  end

  describe '#flow_end', :vcr do
    it 'rejects bad code' do
      expect{auth.flow_end('abc')}.to raise_error(OAuth2::Error)
    end
  end
end