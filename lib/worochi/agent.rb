class Worochi
  class Agent
    attr_accessor :type, :options, :client

    class << self
      def new(opts={})
        service = opts[:service]
        if self.name == 'Worochi::Agent'
          raise Error, 'Invalid service' unless Config.services.include?(service)
          Agent.const_get(class_name(service)).new(opts)
        else
          super
        end
      end

      def class_name(service)
        service.to_s.split('_').map{|e| e.capitalize}.join
      end
    end

    def initialize(opts={})
      set_options(opts)
      @type = options[:service]
      init_client
    end

    def push(items, opts=nil)
      set_options(opts) unless opts.nil?
      items.each { |item| item.content.rewind }
      Worochi::Log.info "Pushing #{items.size} items to #{type}"
      if respond_to?(:push_all)
        push_all(items)
      else
        items.each { |item| push_file(item) }
      end
      Worochi::Log.info "Push to #{type} completed"
    end

    def remove
      Worochi.remove(self)
      nil
    end

    def default_options
      { dir: '/' }
    end

    def set_options(opts={})
      self.options ||= default_options
      options.merge!(opts)
    end

    def set_dir(path)
      options[:dir] = path
    end

    def full_path(item)
      File.join(options[:dir], item.path)
    end
  end
end

Worochi::Config.services.each do |service|
  require "worochi/agent/#{service}"
end