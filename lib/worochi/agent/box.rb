require 'ruby-box'

class Worochi
  # The {Agent} for Box API.
  # @see https://github.com/attachmentsme/ruby-box
  class Agent::Box < Agent
    # Initializes ruby-box client.
    #
    # @return [RubyBox::Client]
    def init_client
      session = RubyBox::Session.new(
        client_id: 'dummy_id',
        access_token: options[:token])
      @client = RubyBox::Client.new(session)
    end

    # Returns a list of files and subdirectories at the remote path specified
    # by `options[:dir]`.
    #
    # @param path [String] path to list instead of the current directory
    # @return [Array<Hash>] list of files and subdirectories
    def list(path=nil)
      remote_path = list_path(path)
      begin
        folder = @client.folder(remote_path)
        raise Error if folder.nil?
        folder.items.map do |elem|
          {
            name: elem.name,
            path: "#{remote_path}/#{elem.name}",
            type: elem.type
          }
        end
      rescue RubyBox::AuthError
        box_error
      end
    end

    # Push a single {Item} to Box.
    #
    # @param item [Item]
    def push_item(item)
      abs_path = full_path(item.path)
      begin
        folder = @client.create_folder(File.dirname(abs_path))
        raise Error if folder.nil?
        folder.upload_file(item.filename, item.content, true)
      rescue RubyBox::AuthError
        box_error
      end
      nil
    end

    # Deletes the file at `path` from Box.
    #
    # @param path [String] path relative to current directory
    # @return [Boolean] `true` if a file was actually deleted
    def delete(path)
      abs_path = full_path(path)
      begin
        file = @client.file(abs_path)
        return false if file.nil?
        file.delete
      rescue RubyBox::AuthError
        box_error
      end
      true
    end

  private

    # Box tokens can expire so the user should check for this error to and
    # refresh the access token when necessary.
    def box_error
      raise Error, 'Box access token is valid or has expired'
    end
  end
end