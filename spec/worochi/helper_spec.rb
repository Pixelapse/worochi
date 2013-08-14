require 'spec_helper'

describe Worochi::Helper do

  describe '.is_s3_path?', :aws do
    it 'recognizes an S3 path' do
      expect(Worochi::Helper.is_s3_path?('s3:test/path')).to be_true
    end

    it 'rejects other paths' do
      expect(Worochi::Helper.is_s3_path?('test/path')).to be_false
      expect(Worochi::Helper.is_s3_path?('s3/test/path')).to be_false
      expect(Worochi::Helper.is_s3_path?('http://a.com/path')).to be_false
    end
  end

  describe '.s3_url', :aws  do
    it 'returns the right S3 URL' do
      Worochi::Config.s3_bucket = 'rspec-test'
      uri = Worochi::Helper.s3_url('s3:test/path')
      expect(uri.path).to eq('/test/path')
      expect(uri.host).to include('rspec-test')
    end

    it 'parses bucket names' do
      uri = Worochi::Helper.s3_url('s3:bucket-name:test/path')
      expect(uri.path).to eq('/test/path')
      expect(uri.host).to include('bucket-name')
    end

    it 'rejects invalid URLs' do
      expect{Worochi::Helper.s3_url('a/b')}.to raise_error(Worochi::Error)
    end
  end
end