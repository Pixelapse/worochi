require 'helper'

describe Worochi::Item do
  describe '.open', :vcr do

    def single_file(file, hash=nil)
      items = Worochi::Item.open(hash || file.source)
      checksum = Digest::SHA2.hexdigest(items.first.content.read)
      expect(items.first.class).to be(Worochi::Item)
      expect(checksum).to eq(file.checksum)
      expect(items.first.path).to eq(hash ? hash[:path] : file.name)
    end

    context 'opens a single file' do
      it 'with String parameter' do
        single_file(remote)
        single_file(local)
      end
      it 'with Hash parameter' do
        single_file(remote, { path: remote.path, source: remote.source })
        single_file(local, { path: local.path, source: local.source })
      end
    end

    context 'opens multiple files' do
      it 'with String parameters' do
        items = Worochi::Item.open([remote.source, local.source])
        checksum = Digest::SHA2.hexdigest(items.last.content.read)
        expect(checksum).to eq(local.checksum)
        expect(items.size).to eq(2)
      end
      it 'with Hash parameters' do
        hashes = [remote, local, remote, local].map do |file|
          { path: file.path, source: file.source }
        end
        items = Worochi::Item.open(hashes)
        checksum = Digest::SHA2.hexdigest(items.last.content.read)
        expect(checksum).to eq(local.checksum)
        expect(items.size).to eq(4)
      end
    end
  end

  describe '.open_single', :vcr do
    it 'accepts a String' do
      item = Worochi::Item.open_single(remote.source)
      expect(item.class).to be(Worochi::Item)
      expect(item.size).to eq(remote.size)
    end

    it 'accepts a Hash' do
      hash = { path: local.path, source: local.source }
      item = Worochi::Item.open_single(hash)
      expect(item.class).to be(Worochi::Item)
      expect(item.size).to eq(local.size)
    end

    it 'works with AWS S3 paths', :aws do
      item = Worochi::Item.open_single(s3.source)
      expect(item.class).to be(Worochi::Item)
      checksum = Digest::SHA2.hexdigest(item.content.read)
      expect(checksum).to eq(s3.checksum)
    end
  end

  describe '#read' do
    it 'reads the content' do
      item = Worochi::Item.open_single(local.source)
      first_word = item.read(4)
      expect(first_word).to eq('This')
      rest = item.read
      expect(rest.size).to eq(local.size - 4)
    end
  end

  describe '#rewind' do
    it 'rewinds the content' do
      item = Worochi::Item.open_single(local.source)
      item.read
      expect(item.read.size).to eq(0)
      expect(item.rewind).to eq(0)
      expect(item.read.size).to eq(local.size)
    end
  end
end