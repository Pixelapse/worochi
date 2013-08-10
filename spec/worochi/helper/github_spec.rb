require 'helper'

describe Worochi::Helper::Github do
  describe Worochi::Helper::Github::StreamIO do

    let(:size) { 114 }
    let(:stream) do
      item = Worochi::Item.open_single(local.source)
      Worochi::Helper::Github::StreamIO.new(item)
    end

    after do
      stream.rewind
    end

    describe '.new' do
      it 'initializes' do
        item = Worochi::Item.open_single(local.source)
        s = Worochi::Helper::Github::StreamIO.new(item)
        expect(s.class).to be(Worochi::Helper::Github::StreamIO)
      end
    end

    describe '#size' do
      it 'returns the encoded size' do
        expect(stream.size).to eq(size)
      end
    end

    describe '#read' do
      it 'encodes a file correctly' do
        checksum = '0bda09766257c6e8d33557cf4d1e1718e82540d46b53d288fc13198e7126f2bc'
        content = stream.read
        expect(Digest::SHA2.hexdigest(content)).to eq(checksum)
        expect(content.size).to eq(size)
      end

      it 'reads partial lengths' do
        part = stream.read(6)
        expect(part).to eq('{"cont')
        expect(part.size).to eq(6)

        part = stream.read(15)
        expect(part).to eq('ent":"VGhpcyBpc')
        expect(part.size).to eq(15)
      end
    end

    describe '#rewind' do
      it 'rewinds the stream' do
        expect(stream.read(20)).to eq('{"content":"VGhpcyBp')
        stream.rewind
        expect(stream.read(20)).to eq('{"content":"VGhpcyBp')
      end
    end
  end
end