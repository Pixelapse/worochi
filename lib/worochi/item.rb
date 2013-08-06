require 'tempfile'

class Worochi
  class Item
    attr_accessor :path, :content
    def initialize(meta={})
      meta.each { |k,v| instance_variable_set("@#{k}", v) }
    end

    def size
      content.size
    end

    def read
      content.read
    end

    class << self

      def open(origin)
        file_list = origin.kind_of?(Array) ? origin : [origin]
        file_list.map { |entry| open_single(entry) }
      end

      def open_single(entry)
        if entry.kind_of?(Hash)
          file = entry[:source]
          path = entry[:path]
        else
          file = entry
        end

        meta = {}

        if File.file?(file)
          meta[:content] = retrieve_local(file)
        else
          url = Helper.is_s3_path?(file) ? Helper.s3_url(file) : file
          meta[:content] = retrieve_remote(url)
        end

        meta[:path] = path || File.basename(file)

        Item.new(meta)
      end

      def retrieve_local(local_path)
        Worochi::Log.debug 'OPEN: ' + local_path
        file = File.open(local_path)
        Worochi::Log.debug "#{file.size} bytes"
        file
      end

      def retrieve_remote(file_url)
        uri = URI(file_url)
        Worochi::Log.debug 'GET: ' + uri.to_s

        file = Tempfile.new('worochi_tmp_')
        file.binmode

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == 'https')
        request = Net::HTTP::Get.new uri

        http.request request do |response|
          response.read_body do |segment|
            # Worochi::Log.debug "Retrieved #{segment.size} bytes"
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