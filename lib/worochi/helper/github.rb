require 'base64'

class Worochi
  module Helper::Github
    class StreamIO
      BLOCK_SIZE = 12288

      def initialize(file)
        file.rewind
        @parts = [
          StringIO.new('{"content":"'),
          Base64IO.new(file),
          StringIO.new('","encoding":"base64"}')
        ]
        @part_no = 0
        @size = @parts.inject(0) {|sum, p| sum + p.size}
      end

      def size
        @size
      end

      def rewind
        @parts.each { |part| part.rewind }
        @part_no = 0
      end

      def read(length=nil, outbuf=nil)
        return length.nil? ? '' : nil if @part_no >= @parts.size
        
        length = length || size
        output = @parts[@part_no].read(length).to_s

        if output.nil?
          return nil if @part_no >= @parts.size
          output = ''
        end

        while output.length < length
          @part_no += 1
          break if @part_no == @parts.size
          output += @parts[@part_no].read(length - output.length).to_s
        end
        if not outbuf.nil?
          outbuf.clear
          outbuf.insert(0, output)
        end
        # Worochi::Log.debug "Streamed #{output.length} bytes"
        output
      end  
    end

    class Base64IO
      def initialize(file)
        file.rewind
        @file = file
        @encoded_size = (@file.size / 3.0).ceil * 4
        @buffer = ''
      end

      def size
        @encoded_size
      end

      def rewind
        @file.rewind
        @buffer = ''
      end

      def read(length=size, outbuf=nil)
        while @buffer.length < length and not @file.eof?
          @buffer += Base64.strict_encode64 @file.read(StreamIO::BLOCK_SIZE)
        end
        @buffer.empty? ? nil : @buffer.slice!(0, length)
      end
    end
  end
end