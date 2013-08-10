require 'helper'

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
      url = Worochi::Helper.s3_url('s3:test/path')
      expect(url.to_s).to match(/^https.+s3\.amazonaws\.com\/test\/path.*/)
    end
  end
end