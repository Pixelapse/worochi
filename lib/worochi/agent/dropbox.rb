require 'dropbox_sdk'

class Worochi
  # The {Agent} for Dropbox API. This wraps around the `dropbox-sdk` gem.
  # @see https://www.dropbox.com/developers/core/start/ruby
  class Agent::Dropbox < Agent
    # @return [Hash] default options for Dropbox
    def default_options
      {
        service: :dropbox,
        chunk_size: 2*1024*1024,
        overwrite: true,
        dir: '/'
      }
    end

    # Initializes Dropbox SDK client. Refer to
    # {https://www.dropbox.com/developers/core/start/ruby
    # official Dropbox documentation}.
    #
    # @return [DropboxClient]
    def init_client
      @client = DropboxClient.new(options[:token])
      @client
    end

    # Push a single {Item} to Dropbox.
    #
    # @param item [Item]
    # @return [nil]
    def push_item(item)
      Worochi::Log.debug "Uploading #{item.path} (#{item.size} bytes) to Dropbox..."
      if item.size > options[:chunk_size]
        push_item_chunked(item)
      else
        @client.put_file(full_path(item), item.content, options[:overwrite])
      end
      Worochi::Log.debug "Uploaded"
      nil
    end

    # Returns a list of files and subdirectories at the remote path specified
    # by `options[:dir]`.
    #
    # @param path [String] path to list instead of the current directory
    # @return [Array<Hash>] list of files and subdirectories
    def list(path=nil)
      remote_path = path || options[:dir]
      begin
        response = @client.metadata(remote_path)
      rescue DropboxError
        raise Error, 'Invalid Dropbox folder specified'
      end

      response['contents'].map do |elem|
        {
          name: elem['path'].split('/').last,
          path: elem['path'],
          type: elem['is_dir'] ? 'folder' : 'file'
        }
      end
    end

    # Uses the `/chunked_upload` endpoint to push large files to Dropbox.
    # Refer to {https://www.dropbox.com/developers/core/docs#chunked-upload
    # API documentation}.
    #
    # @param item [Item]
    # @return [nil]
    def push_item_chunked(item)
      Worochi::Log.debug "Using chunk uploader..."
      uploader = @client.get_chunked_uploader(item.content, item.size)
      while uploader.offset < uploader.total_size
          begin
              uploader.upload(options[:chunk_size])
          rescue DropboxError
              raise Error, 'Dropbox chunk upload failed'
          end
          Worochi::Log.debug "Uploaded #{uploader.offset} bytes"
      end
      uploader.finish(full_path(item), options[:overwrite])
      nil
    end

    # Deletes the file at `path` from Dropbox.
    #
    # @param path [String] path relative to current directory
    # @return [Boolean] `true` if a file was actually deleted
    def delete(path)
      begin
        @client.file_delete(File.join(options[:dir], path))
      rescue DropboxError
        false
      end
      true
    end
  end
end