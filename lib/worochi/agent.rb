class Worochi
  # The parent class for all service agents.
  class Agent
    # Service name.
    # @return [Symbol]
    attr_reader :type
    # Service options.
    # @return [Hash]
    attr_accessor :options

    # @param opts [Hash] service options
    def initialize(opts={})
      set_options(opts)
      @type = options[:service]
      init_client
    end

    # Push list of files to the service. Refer to {Item.open} for how to
    # format the file list. An optional `opts` hash can be used to update the
    # agent options before pushing.
    #
    # @param origin [Array<Hash>, Array<String>, Hash, String]
    # @param opts [Hash] update agent options before pushing
    # @return [nil]
    # @see Item.open
    # @example
    #     agent = Worochi.create(:github, 'sfsFj41na89cx')
    #     agent.push({ source: 'http://a.com/file.jpg', path: 'folder/file.jpg' })
    def push(origin, opts=nil)
      set_options(opts) unless opts.nil?
      items = Item.open(origin)
      push_items(items)
      nil
    end

    # Push a list of {Item} to the service. Usually called by {#push}.
    #
    # @param items [Array<Item>]
    # @return [nil]
    def push_items(items)
      items.each { |item| item.content.rewind }
      Worochi::Log.info "Pushing #{items.size} items to #{type}"
      if respond_to?(:push_all)
        push_all(items)
      else
        items.each { |item| push_item(item) }
      end
      Worochi::Log.info "Push to #{type} completed"
      nil
    end

    # Remove the agent from the list of active agents responding to calls to
    # {Worochi.push}.
    #
    # @return [nil]
    def remove
      Worochi.remove(self)
      nil
    end

    # Returns a list of subdirectories at the remote path specified by
    # `options[:dir]`. Relies on the service-specific implementation of
    # `#list`.
    #
    # @return [Array<String>, Array<Hash>] list of subdirectories
    # @example
    #     agent = Worochi.create(:dropbox, 'sfsFj41na89cx', dir: '/abc')
    #     agent.folders # => ["folder1", "folder2"]
    #     agent.folders(true)
    #     # => [
    #     #      { name: "folder1", type: "folder", path: "/abc/folder1"},
    #     #      { name: "folder2", type: "folder", path: "/abc/folder2"}
    #     #    ]
    def folders(details=false)
      result = list.reject { |elem| elem[:type] != 'folder' }
      result.map! { |elem| elem[:name] } unless details
      result
    end

    # Returns a list of files at the remote path specified by `options[:dir]`.
    # Relies on the service-specific implementation of `#list`.
    #
    # @return [Array<String>, Array<Hash>] list of files
    # @example
    #     agent = Worochi.create(:dropbox, 'sfsFj41na89cx', dir: '/abc')
    #     agent.files # => ["k.jpg", "t.txt"]
    #     agent.files(true)
    #     # => [
    #     #      { name: "k.jpg", type: "file", path: "/abc/k.jpg"},
    #     #      { name: "t.txt", type: "file", path: "/abc/t.txt"}
    #     #    ]
    def files(details=false)
      result = list.reject { |elem| elem[:type] != 'file' }
      result.map! { |elem| elem[:name] } unless details
      result
    end

    # Updates {.options} using `opts`.
    #
    # @param opts [Hash] new options
    # @return [Hash] the updated options
    def set_options(opts={})
      self.options ||= default_options
      options.merge!(opts)
    end

    # Sets the remote target directory path. This is the same as modifying
    # `options[:dir]`.
    #
    # @param path [String] the new path
    # @return [Hash] the updated options
    def set_dir(path)
      options[:dir] = path
      options
    end

  private
    # @return [String] full path combining remote directory and item path
    def full_path(item)
      File.join(options[:dir], item.path)
    end

    # Agents should override this.
    #
    # @return [nil]
    def default_options
      raise Error, 'Default options not specified.'
    end

    class << self
    public
      # Creates a new service-specific {Agent} based on `:service`.
      #
      # @param opts [Hash] service options; must contain `:service` key.
      # @return [Agent]
      # @example
      #     Worochi::Agent.new({ service: :github, token:'6st46setsybhd64' })
      def new(opts={})
        service = opts[:service]
        if self.name == 'Worochi::Agent'
          raise Error, 'Invalid service' unless Config.services.include?(service)
          Agent.const_get(class_name(service)).new(opts)
        else
          super
        end
      end

    private
      # Returns the class name for the {Agent} given a service name
      #
      # @return [String]
      # @example
      #     class_name(:google_drive) # => "GoogleDrive"
      def class_name(service)
        service.to_s.split('_').map{|e| e.capitalize}.join
      end
    end
  end
end

Worochi::Config.services.each do |service|
  require "worochi/agent/#{service}"
end