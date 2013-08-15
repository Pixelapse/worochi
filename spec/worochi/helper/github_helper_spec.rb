require 'spec_helper'

class Worochi::Agent::Github
  describe Helper do
    describe Helper::StreamIO do

      let(:size) { 114 }
      let(:checksum) { '0bda09766257c6e8d33557cf4d1e1718e82540d46b53d288fc13198e7126f2bc' }
      let(:stream) do
        item = Worochi::Item.open_single(local.source)
        Helper::StreamIO.new(item)
      end

      after do
        stream.rewind
      end

      describe '.new' do
        it 'initializes' do
          item = Worochi::Item.open_single(local.source)
          s = Helper::StreamIO.new(item)
          expect(s.class).to be(Helper::StreamIO)
        end
      end

      describe '#size' do
        it 'returns the encoded size' do
          expect(stream.size).to eq(size)
        end
      end

      describe '#read' do
        def verify(content)
          expect(Digest::SHA2.hexdigest(content)).to eq(checksum)
          expect(content.size).to eq(size)
        end

        it 'encodes a file correctly' do
          content = stream.read
          verify(content)
        end

        it 'reads partial lengths' do
          part = stream.read(6)
          expect(part).to eq('{"cont')
          expect(part.size).to eq(6)

          part = stream.read(15)
          expect(part).to eq('ent":"VGhpcyBpc')
          expect(part.size).to eq(15)
        end

        it 'tracks file positions correctly' do
          content = stream.read(stream.size)
          verify(content)
          stream.rewind
          content = stream.read(stream.size + 100)
          verify(content)
          stream.rewind
          content = stream.read(stream.size - 10)
          content += stream.read(10)
          verify(content)
        end

        it 'accepts an output buffer' do
          outbuf = ''
          stream.read(5, outbuf)
          expect(outbuf.size).to eq(5)
          expect(outbuf).to eq('{"con')
          stream.read
          expect(stream.read(5, outbuf)).to be(nil)
          expect(outbuf).to eq('')
        end

        it 'terminates correctly' do
          stream.read(stream.size)
          expect(stream.read(10)).to be(nil)
          expect(stream.read).to eq('')
        end
      end

      describe '#rewind' do
        it 'rewinds the stream' do
          expect(stream.read(20)).to eq('{"content":"VGhpcyBp')
          stream.rewind
          expect(stream.read(20)).to eq('{"content":"VGhpcyBp')
          stream.read
          stream.rewind
          expect(stream.read(20)).to eq('{"content":"VGhpcyBp')
        end
      end
    end
  end
end