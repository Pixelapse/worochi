require 'base64'

class Worochi
  class Agent::Github
    # Helper classes for GitHub JSON streaming.
    module Helper
      # Size to read in. Must be a multiple of 3 for Base64 streaming.
      BLOCK_SIZE = 12288

      # This is a wrapper that produces a JSON stream that works with
      # `Net::HTTP::Post#body_stream`.
      class StreamIO

        def initialize(item)
          item.content.rewind
          @parts = [
            StringIO.new('{"content":"'),
            Base64IO.new(item.content),
            StringIO.new('","encoding":"base64"}')
          ]
          @part_no = 0
          @size = @parts.inject(0) {|sum, p| sum + p.size}
        end

        # @return [Integer] size of the JSON
        def size
          @size
        end

        # Rewind each component of the stream.
        #
        # @return [nil]
        def rewind
          @parts.each { |part| part.rewind }
          @part_no = 0
          nil
        end

        # @param length [Integer]
        # @param outbuf [IO]
        # @return [String]
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

          output
        end  
      end

      # This is a wrapper around the file content that streams the file as a
      # Base64 encoded string.
      class Base64IO
        def initialize(file)
          file.rewind
          @file = file
          @encoded_size = (@file.size / 3.0).ceil * 4
          @buffer = ''
        end

        # @return [Integer] size of the JSON
        def size
          @encoded_size
        end

        # Rewind the stream.
        def rewind
          @file.rewind
          @buffer = ''
          nil
        end

        # @param length [Integer]
        # @param outbuf [IO]
        # @return [String]
        def read(length=size, outbuf=nil)
          while @buffer.length < length and not @file.eof?
            @buffer += Base64.strict_encode64 @file.read(BLOCK_SIZE)
          end
          @buffer.empty? ? nil : @buffer.slice!(0, length)
        end
      end
    end
  end
end