require 'yaml'

class Worochi
  # The parent class for all service agents.
  class Agent
    # Service options.
    # @return [Hashie::Mash]
    attr_accessor :options

    # @param opts [Hash] service options
    def initialize(opts={})
      set_options(opts)
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

    # Returns a list of files at the remote path specified by `options[:dir]`.
    # Relies on the service-specific implementation of `#list`.
    # 
    # @overload files(details)
    #   @param details [Boolean] display more information
    # @overload files(path, details=false)
    #   @param path [String] remote path to list instead of current directory
    #   @param details [Boolean] display more information
    # @return [Array<String>, Array<Hash>] list of files
    # @example
    #     agent = Worochi.create(:dropbox, 'sfsFj41na89cx', dir: '/abc')
    #     agent.files # => ["k.jpg", "t.txt"]
    #     agent.files(true)
    #     # => [
    #     #      { name: "k.jpg", type: "file", path: "/abc/k.jpg"},
    #     #      { name: "t.txt", type: "file", path: "/abc/t.txt"}
    #     #    ]
    def files(*args)
      list_helper(:files, args)
    end

    # Returns a list of subdirectories at the remote path specified by
    # `options[:dir]`. Relies on the service-specific implementation of
    # `#list`. Refer to {#files} for overloaded prototypes.
    #
    # @return [Array<String>, Array<Hash>] list of subdirectories
    # @see #files
    # @example
    #     agent = Worochi.create(:dropbox, 'sfsFj41na89cx', dir: '/abc')
    #     agent.folders # => ["folder1", "folder2"]
    def folders(*args)
      list_helper(:folders, args)
    end

    # Returns a list of files and folders at the remote path specified by
    # `options[:dir]`. Relies on the service-specific implementation of
    # `#list`. Refer to {#files} for overloaded prototypes.
    #
    # @return [Array<String>, Array<Hash>] list of files and folders
    def files_and_folders(*args)
      list_helper(:both, args)
    end

    # Updates {.options} using `opts`.
    #
    # @param opts [Hash] new options
    # @return [Hashie::Mash] the updated options
    def set_options(opts={})
      self.options ||= default_options
      opts = Hashie::Mash.new(opts)
      options.merge!(opts)
    end

    # Sets the remote target directory path. This is the same as modifying
    # `options[:dir]`.
    #
    # @param path [String] the new path
    # @return [Hashie::Mash] the updated options
    def set_dir(path)
      options.dir = path
      options
    end

    # Returns the service type for the agent.
    #
    # @return [Symbol] service type
    def type
      options.service
    end

    # Returns the display name for the agent's service.
    #
    # @return [String] display name
    def name
      Worochi::Config.service_display_name(options.service)
    end

  private
    # Parses the arguments for {#files} and {#folders}.
    #
    # @param mode [Symbol] display files, folders, or both
    # @param args [Array] argument list
    # @return [Array<String>, Array<Hashie::Mash>] list of files or folders
    def list_helper(mode, args)
      details = args[0] == true ? true : false
      if args[0].respond_to?(:length)
        path = args[0]
        details = args[1] == true ? true : false
      end

      case mode
      when :files
        excluded = 'folder'
      when :folders
        excluded = 'file'
      else
        excluded = nil
      end

      result = list(path).reject { |elem| elem[:type] == excluded }
      if details
        result.map! { |elem| Hashie::Mash.new(elem) }
      else
        result.map! { |elem| elem[:name] }
      end
      result
    end

    # Returns the full remote target path for the file being pushed. If the
    # specified path starts with / then this is assumed to be the full
    # absolute path. If not, join the path with the configured directory.
    #
    # @param path [String] path to the file
    # @return [String] full path combining remote directory and item path
    def full_path(path)
      if path[0] == '/'
        path
      else
        File.join(options.dir, path)
      end
    end

    # Path used for listing. Defaults to `options[:dir]` if not specified.
    #
    # @param path [String] relative/absolute path or nil
    # @return [String] absolute path to list
    def list_path(path)
      if path.nil? || path.empty?
        options.dir
      else
        return full_path(path)
      end
    end

    # Agents should either override this or have a YAML config file at
    # config/service_name.yml.
    #
    # @return [Hashie::Mash] options parsed from YAML config
    def default_options
      service = service_name.to_sym
      Worochi::Config.service_opts(service)
    end

    # Returns the service name based on the class name.
    #
    # @return [Symbol] service name
    def service_name
      name = self.class.to_s.split( '::' ).last
      name.gsub!(/::/, '/')
      name.gsub!(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
      name.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
      name.tr!("-", "_")
      name.downcase!
      name.to_sym
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
  begin
    require "worochi/agent/#{service}"
  rescue LoadError # yml is defined but not the agent
  end
end