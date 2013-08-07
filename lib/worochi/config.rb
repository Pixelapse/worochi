class Worochi
  # Configurations for Worochi.
  module Config
    @services = [:github, :dropbox]
    @s3_bucket = 'data-pixelapse'
    @s3_prefix = 's3'

    class << self
      # Array of service names. 
      # @return [Array<Symbol>]
      attr_reader :services

      # Name of S3 bucket.
      # @return [String]
      attr_reader :s3_bucket

      # Prefix for S3 resource paths.
      # @return [String]
      attr_reader :s3_prefix
    end
  end
end

