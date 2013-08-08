class Worochi
  # Configurations for Worochi.
  module Config
    @services = {
      github: 'GitHub',
      dropbox: 'Dropbox'
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
      # @param service [Symbol]
      # @param [Stirng] display name
      def humanize_service(service)
        @services[service]
      end

      # Name of S3 bucket.
      #
      # @return [String]
      attr_reader :s3_bucket

      # Prefix for S3 resource paths.
      #
      # @return [String]
      attr_reader :s3_prefix
    end
  end
end

