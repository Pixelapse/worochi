require 'tempfile'
require 'mime/types'

# Install ruby-filemagic if you want better mime-type identification
begin
  require 'filemagic'
rescue LoadError
end

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

    # @param path [String] relative destination path including file name
    # @param content [IO] file content
    def initialize(path, content)
      @path = path
      @content = content
      detect_type
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
      content.read(*args)
    end

    # Rewinds the content. This is just a wrapper for the `#rewind` method on
    # {#content}.
    #
    # @return [0]
    def rewind
      content.rewind
    end

    # @return [String] mime-type of the content.
    def content_type
      @type
    end

  private
    # Detects the mime-type of the file. Uses file name matching if
    # ruby-filemagic is not installed.
    #
    # @param simplified [Boolean] whether to use simplified mime-types
    # @return [String] mime-type
    def detect_type(simplified=true)
      begin
        # Magic number matching
        fm = FileMagic.mime
        fm.simplified = true if simplified
        @type = fm.file(@content.path)
      rescue Worochi::Error
        # File name matching
        types = MIME::Types.type_for(@content.path)
        if types.empty?
          @type = 'application/octet-stream'
        else
          @type = simplified ? types[0].content_type : types[0].simplified
        end
      end
      @type
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
          source = entry[:source] || entry['source']
          path = entry[:path] || entry['path']
        else
          source = entry
        end

        Item.new(path || File.basename(source), retrieve(source))
      end

    private
      # Retrieves the file content from `source`.
      #
      # @param source [String] local or remote location of the file content
      # @return [File]
      def retrieve(source)
        if File.file?(source)
          retrieve_local(source)
        else
          if Config.s3_enabled? && Helper.is_s3_path?(source)
            source = Helper.s3_url(source)
          end
          retrieve_remote(source)
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

      # Downloads a remote file using `HTTP::Get`.
      #
      # @param file_url [String, URI] the URL of the file
      # @return [Tempfile] the downloaded file
      def retrieve_remote(file_url)
        uri = URI(file_url)
        Worochi::Log.debug 'GET: ' + uri.to_s

        file = Tempfile.new('worochi_tmp_')
        file.binmode

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == 'https')
        request = Net::HTTP::Get.new(uri.request_uri)

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