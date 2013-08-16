class Worochi
  # Configuration methods for loading and modifying options.
  module Config
    class << self
      # Loads options from YAML configuration files.
      #
      # @return [nil]
      def load_yaml
        @options = {}
        services.each do |service|
          path = File.join(File.dirname(__FILE__), "config/#{service}.yml")
          raise Error, "Missing config for #{service}" unless File.file?(path)
          @options[service] = Hashie::Mash.new(YAML.load_file(path))
          @options[service].service = service
        end
      end

      # Returns the service configurations that was loaded from YAML.
      #
      # @return [Hashie::Mash]
      def service_opts(service)
        if service.nil? || @options.nil? || @options[service].nil?
          raise Error, "Invalid service (#{service}) specified"
        end
        @options[service].clone
      end

      # Array of service names. Parsed from the file names of any .yml file
      # names in the worochi/config directory, excluding ones that contain the
      # `#` character.
      #
      # @return [Array<Symbol>]
      def services
        return @services if @services
        files = Dir[File.join(File.dirname(__FILE__), 'config/[^#]*.yml')]
        @services = files.map do |file|
          File.basename(file, '.yml').to_sym
        end
        @services
      end

      # Array of service meta information.
      #
      # @return [Array<Hashie::Mash>]
      def list_services
        services.map do |service|
          Hashie::Mash.new({
            service: service,
            display_name: service_display_name(service),
            id: service_id(service)
          })
        end
      end

      # Returns display name for the service.
      #
      # @overload service_display_name(service)
      #   @param service [Symbol]
      # @overload service_display_name(service_id)
      #   @param service_id [Integer]
      # @return [String] display name
      def service_display_name(arg)
        service = arg.to_sym if arg.respond_to?(:to_sym)
        service = service_name(arg) unless @options.include?(service)
        if service.nil?
          nil
        else
          @options[service].display_name
        end
      end

      # Returns the service ID for the service, which can be used as a
      # primary key for databases.
      #
      # @param service [Symbol]
      # @return [Integer] service ID
      def service_id(service)
        if @options[service.to_sym].nil?
          nil
        else
          @options[service.to_sym].id
        end
      end

      # Returns the service name given the service ID.
      #
      # @param id [Integer]
      # @return [Symbol] if service exists
      # @return [nil] if service does not exist
      def service_name(id)
        @service_names ||= {}
        return @service_names[id] if @service_names.include?(id)
        @options.each do |key, value|
          if value.id == id
            @service_names[value.id] = key
            return key
          end
        end
        nil
      end

      # Enables AWS S3 support. AWS_SECRET_ACCESS_KEY and AWS_ACCESS_KEY_ID
      # should be present in ENV.
      #
      # @return [Boolean]
      attr_accessor :s3_enabled

      # Name of S3 bucket.
      #
      # @return [String]
      attr_accessor :s3_bucket

      # Prefix for S3 resource paths.
      #
      # @return [String]
      attr_accessor :s3_prefix

      # Logging device.
      #
      # @return [IO]
      attr_accessor :logdev

      # Disable debug and error messages if `true`.
      #
      # @return [Boolean]
      attr_accessor :silent

      alias_method :silent?, :silent
      alias_method :s3_enabled?, :s3_enabled

    end
  end
end

