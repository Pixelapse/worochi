class Worochi
  # The {Agent} for an example API.
  # This is a sample of methods that should be implemented by a service agent.
  class Agent::Example < Agent
    # This is where the service-specific API client should be initialized.
    #
    # @return [ApiClient]
    # @see Agent#initialize
    def init_client
      @client = nil
    end

    # Defined for services that need to push all the items together as a
    # batch. For example, GitHub needs to make one commit for all the files.
    # Usually a service-specific implementation should only need one of either
    # {#push_item} or {#push_all}.
    #
    # @return [nil]
    # @see Agent#push_items
    def push_all(items)
      items.each { |item| @client.push(item.content, item.path) }
    end

    # Pushes an individual item to the service. Usually a service-specific
    # implementation should only need one of either {#push_item} or
    # {#push_all}.
    #
    # @return [nil]
    # @see Agent#push_items
    def push_item(item)
      @client.push(item.content, item.path)
    end

    # Returns a list of files and subdirectories at the remote path specified
    # by `options[:dir]`. Each file entry is a hash that should contain at
    # least the keys `:name`, `:path`, and `:type`, but can also contain other
    # service-specific meta information.
    #
    # @param path [String] path to list instead of the current directory
    # @return [Array<Hash>] list of files and subdirectories
    # @see Agent#folders
    # @see Agent#files
    def list(path=nil)
      remote_path = list_path(path)
      result = @client.get_file_list(remote_path)
      result.map do |elem|
        {
          name: elem.name,
          path: elem.path,
          type: elem.type
        }
      end
    end

    # Deletes the file at path. Raises {Error} if file deletion is not
    # supported by the service.
    def delete(path)
      raise Error, 'Deletion is not supported'
    end

    # Service specific methods
  end
end