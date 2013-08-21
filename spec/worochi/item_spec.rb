require 'spec_helper'

describe Worochi::Item do
  describe '.open', :vcr do

    def single_file(file, hash=nil)
      items = Worochi::Item.open(hash || file.source)
      checksum = Digest::SHA2.hexdigest(items.first.content.read)
      expect(items.first.class).to be(Worochi::Item)
      expect(checksum).to eq(file.checksum)
      path = hash ? hash[:path] || hash['path'] : file.name
      expect(items.first.path).to eq(path)
    end

    context 'with a single file' do
      it 'accepts String parameter' do
        single_file(remote)
        single_file(local)
      end
      it 'accepts Hash parameter' do
        single_file(remote, { path: remote.path, source: remote.source })
        single_file(local, { path: local.path, source: local.source })
      end
      it 'symbolizes keys' do
        single_file(local, { 'path' => local.path, 'source' => local.source })
      end
    end

    context 'with multiple files' do
      it 'accepts String parameters' do
        items = Worochi::Item.open([remote.source, local.source])
        checksum = Digest::SHA2.hexdigest(items.last.content.read)
        expect(checksum).to eq(local.checksum)
        expect(items.size).to eq(2)
      end
      it 'accepts Hash parameters' do
        hashes = [remote, local, remote, local].map do |file|
          { path: file.path, source: file.source }
        end
        items = Worochi::Item.open(hashes)
        checksum = Digest::SHA2.hexdigest(items.last.content.read)
        expect(checksum).to eq(local.checksum)
        expect(items.size).to eq(4)
      end
      it 'symbolizes keys' do
        hashes = [local, local, local].map do |file|
          { 'path' => file.path, 'source' => file.source }
        end
        items = Worochi::Item.open(hashes)
        checksum = Digest::SHA2.hexdigest(items.last.content.read)
        expect(checksum).to eq(local.checksum)
        expect(items.size).to eq(3)
      end
    end
  end

  describe '.open_single', :vcr do
    it 'accepts a String' do
      item = Worochi::Item.open_single(remote.source)
      expect(item.class).to be(Worochi::Item)
      expect(item.size).to eq(remote.file_size)
    end

    it 'accepts a Hash' do
      hash = { path: local.path, source: local.source }
      item = Worochi::Item.open_single(hash)
      expect(item.class).to be(Worochi::Item)
      expect(item.size).to eq(local.file_size)
    end

    it 'works with AWS S3 paths', :aws do
      Worochi::Config.s3_bucket = 'data-pixelapse'
      item = Worochi::Item.open_single(s3.source)
      expect(item.class).to be(Worochi::Item)
      content = item.content.read
      checksum = Digest::SHA2.hexdigest(content)
      expect(checksum).to eq(s3.checksum)
      expect(content.size).to eq(s3.file_size)
    end
  end

  describe '#read' do
    it 'reads the content' do
      item = Worochi::Item.open_single(local.source)
      first_word = item.read(4)
      expect(first_word).to eq('This')
      rest = item.read
      expect(rest.size).to eq(local.file_size - 4)
    end
  end

  describe '#rewind' do
    it 'rewinds the content' do
      item = Worochi::Item.open_single(local.source)
      item.read
      expect(item.read.size).to eq(0)
      expect(item.rewind).to eq(0)
      expect(item.read.size).to eq(local.file_size)
    end
  end

  describe '#content_type', :vcr do
    it 'detects the MIME type' do
      item = Worochi::Item.open_single(local.source)
      expect(item.content_type).to eq('text/plain')
    end
    it 'falls back to file name when ruby-filemagic is not loaded' do
      temp = FileMagic
      Object.send(:remove_const, :FileMagic)
      item = Worochi::Item.open_single(local.source)
      expect(item.content_type).to eq('application/octet-stream')
      item = Worochi::Item.open_single(remote.source)
      expect(item.content_type).to eq('image/gif')
      FileMagic = temp
    end
  end
end