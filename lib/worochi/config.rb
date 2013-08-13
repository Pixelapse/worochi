class Worochi
  # Configurations for Worochi.
  module Config
    @services = {
      github: [1, 'GitHub'],
      dropbox: [2, 'Dropbox']
    }
    @s3_bucket = 'data-pixelapse'
    @s3_prefix = 's3'

    class << self
      # Array of service names. 
      #
      # @return [Array<Symbol>]
      def services
        @services.keys
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
        service = service_name(arg) unless @services.include?(service)
        if service.nil?
          nil
        else
          @services[service][1]
        end
      end

      # Returns the service ID for the service, which can be used as a
      # primary key for databases.
      #
      # @param service [Symbol]
      # @return [Integer] service ID
      def service_id(service)
        if @services[service.to_sym].nil?
          nil
        else
          @services[service.to_sym][0]
        end
      end

      # Returns the service name given the service ID.
      #
      # @param service_id [Integer]
      # @return [Symbol] if service exists
      # @return [nil] if service does not exist
      def service_name(service_id)
        @service_ids ||= {}
        return @service_ids[service_id] if @service_ids.include?(service_id)
        @services.each do |key, value|
          if value[0] == service_id
            @service_ids[value[0]] = key
            return key
          end
        end
        nil
      end

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
    end
  end
end

