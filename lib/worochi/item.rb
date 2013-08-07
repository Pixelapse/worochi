require 'tempfile'

class Worochi
  # This represents a single file that is being pushed. The {#content}
  # attribute holds an IO object that is read by the push agent and the
  # {#path} attribute is the relative path to the remote target directory that
  # the file will be pushed to.
  class Item
    # The relative path of the object from the target root directory. If
    # the {Item} was initialized without a `:path` option, this attribute
    # defaults to the file name.
    # @return [String]
    attr_accessor :path

    # An IO object containing the content of the file being pushed.
    # @return [IO]
    attr_accessor :content
    def initialize(opts={})
      @path = opts[:path]
      raise Error, 'Missing Item content' if !opts[:content]
      @content = opts[:content]
      @content.rewind
    end

    # The total size of the content in bytes.
    #
    # @return [Integer]
    def size
      content.size
    end

    # Read from the content. This is just a wrapper for the `#read` method on
    # {#content} and any arguments will be passed on to the IO object. 
    #
    # @return [String]
    def read(*args)
      content.read(args)
    end

    class << self
      # Takes in either a single file entry or a list of file entries and
      # parses them into a list of {Item} objects. Each entry can be either a
      # String specifying the source location of the file, or a Hash
      # specifying both the `:source` location and the remote `:path` to push
      # the file to.
      #
      # @example Single file
      #     Item.open('folder/file.txt')
      # @example Multiple files
      #     Item.open(['folder/file1.txt', 'folder/file2.txt'])
      # @example Remote path
      #     Item.open({
      #       source: 'http://a.com/file.jpg',
      #       path: 'folder/file.jpg'
      #     })
      # @example Remote path with mixed origins
      #     a = { source: 'http://a.com/file.jpg', path: 'folder/file1.jpg' }
      #     b = { source: 'folder/file.jpg', path: 'folder/file2.jpg' }
      #     c = { source: 's3:folder/file.jpg', path: 'folder/file3.jpg' }
      #     Item.open([a, b, c])
      #     # c is an example of retrieving files using an AWS S3 path
      #
      # @param origin [Array<Hash>, Array<String>, Hash, String]
      # @return [Array<Item>]
      def open(origin)
        file_list = origin.kind_of?(Array) ? origin : [origin]
        file_list.map { |entry| open_single(entry) }
      end

      # Takes in a single entry from {.open} and creates an {Item}.
      #
      # @param entry [Hash, String] the file metadata
      # @return [Item] the file item
      def open_single(entry)
        if entry.kind_of?(Hash)
          source = entry[:source]
          path = entry[:path]
        else
          source = entry
        end

        Item.new({
          path: path || File.basename(source),
          content: retrieve(source)
        })
      end

      # Retrieves the file content from `source`.
      #
      # @param source [String] local or remote location of the file content
      # @return [File]
      def retrieve(source)
        if File.file?(source)
          retrieve_local(source)
        else
          url = Helper.is_s3_path?(source) ? Helper.s3_url(source) : source
          retrieve_remote(url)
        end        
      end

      # Retrieves the local file.
      #
      # @param local_path [String] local path to the file
      # @return [File]
      def retrieve_local(local_path)
        Worochi::Log.debug 'OPEN: ' + local_path
        file = File.open(local_path)
        Worochi::Log.debug "#{file.size} bytes"
        file
      end

      # Downloads a remote file using {HTTP::Get}.
      #
      # @param file_url [String, URI] the URL of the file
      # @return [Tempfile] the downloaded file
      def retrieve_remote(file_url)
        Worochi::Log.debug file_url.class
        uri = URI(file_url)
        Worochi::Log.debug 'GET: ' + uri.to_s

        file = Tempfile.new('worochi_tmp_')
        file.binmode

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == 'https')
        request = Net::HTTP::Get.new uri

        http.request request do |response|
          response.read_body do |segment|
            file.write segment
          end
        end
        Worochi::Log.debug "Downloaded #{file.size} bytes"
        file.rewind
        file
      end
    end
  end
end