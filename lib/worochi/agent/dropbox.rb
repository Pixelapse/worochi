require 'dropbox_sdk'

class Worochi
  class Agent::Dropbox < Agent

    # General agent methods

    def default_options
      {
        chunk_size: 2*1024*1024,
        overwrite: true,
        dir: '/'
      }
    end

    def init_client
      @client = DropboxClient.new(options[:token])
    end

    def push_file(item)
      Worochi::Log.debug "Uploading #{item.path} (#{item.size} bytes) to Dropbox..."
      if item.size > options[:chunk_size]
        push_file_chunked(item)
      else
        client.put_file(full_path(item), item.content, options[:overwrite])
      end
      Worochi::Log.debug "Uploaded"
    end

    def folders
      remote_path = options[:dir]
      begin
        response = @client.metadata(remote_path)
      rescue DropboxError
        raise Error, 'Invalid Dropbox folder specified'
      end

      list = response['contents']
      list.map do |item|
        {
          name: item['path'].split('/').last,
          path: item['path'],
          type: item['is_dir'] ? 'dir' : 'file'
        }
      end
    end

    # Dropbox specific methods

    def push_file_chunked(item)
      Worochi::Log.debug "Using chunk uploader..."
      uploader = @client.get_chunked_uploader(item.content, item.size)
      while uploader.offset < uploader.total_size
          begin
              uploader.upload(options[:chunk_size])
          rescue DropboxError
              Worochi::Log.error 'Dropbox chunk upload failed'
              break
          end
          Worochi::Log.debug "Uploaded #{uploader.offset} bytes"
      end
      uploader.finish(full_path(item), options[:overwrite])
    end
  end
end