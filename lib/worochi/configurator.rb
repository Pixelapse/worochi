class Worochi
  # Configuration methods for loading and modifying options.
  module Config
    class << self
      # Loads options from YAML configuration files.
      #
      # @return [nil]
      def load_yaml
        @options = {}
        @services.each do |service|
          path = File.join(File.dirname(__FILE__), "config/#{service}.yml")
          raise Error, "Missing config for #{service}" unless File.file?(path)
          @options[service] = YAML.load_file(path).inject({}) do |memo, (k ,v)|
            memo[k.to_sym] = v
            memo
          end
        end
        @initialized = true
      end

      # Returns the service configurations that was loaded from YAML.
      #
      # @return [Hash]
      def service_opts(service)
        load_yaml unless @initialized
        if service.nil? || @options.nil? || @options[service].nil?
          raise Error, "Invalid service (#{service}) specified"
        end
        @options[service].clone
      end

      # Array of service names. 
      #
      # @return [Array<Symbol>]
      def services
        @services
      end

      # Returns display name for the service.
      #
      # @overload service_display_name(service)
      #   @param service [Symbol]
      # @overload service_display_name(service_id)
      #   @param service_id [Integer]
      # @return [String] display name
      def service_display_name(arg)
        load_yaml unless @initialized
        service = arg.to_sym if arg.respond_to?(:to_sym)
        service = service_name(arg) unless @options.include?(service)
        if service.nil?
          nil
        else
          @options[service][:display_name]
        end
      end

      # Returns the service ID for the service, which can be used as a
      # primary key for databases.
      #
      # @param service [Symbol]
      # @return [Integer] service ID
      def service_id(service)
        load_yaml unless @initialized
        if @options[service.to_sym].nil?
          nil
        else
          @options[service.to_sym][:id]
        end
      end

      # Returns the service name given the service ID.
      #
      # @param id [Integer]
      # @return [Symbol] if service exists
      # @return [nil] if service does not exist
      def service_name(id)
        load_yaml unless @initialized
        @service_names ||= {}
        return @service_names[id] if @service_names.include?(id)
        @options.each do |key, value|
          if value[:id] == id
            @service_names[value[:id]] = key
            return key
          end
        end
        nil
      end

      # Enables AWS S3 support. AWS_SECRET_ACCESS_KEY and AWS_ACCESS_KEY_ID
      # should be present in ENV.
      #
      # @return [Boolean]
      attr_reader :s3_enabled

      # Name of S3 bucket.
      #
      # @return [String]
      attr_reader :s3_bucket

      # Prefix for S3 resource paths.
      #
      # @return [String]
      attr_reader :s3_prefix

      # Disable debug and error messages if `true`.
      #
      # @return [Boolean]
      attr_accessor :silent

      alias_method :silent?, :silent
      alias_method :s3_enabled?, :s3_enabled
    end
  end
end

