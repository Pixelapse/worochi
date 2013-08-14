

class Worochi
  # Contains any global helper methods not specific to any individual service.
  module Helper
    # AWS S3 helpers
    if Worochi::Config.s3_enabled?
      require 'aws-sdk'
      class << self
        # Given an S3 path, return the full URL for the corresponding object
        # determined using the AWS SDK.
        #
        # @param path [String]
        # @return [URI::HTTP]
        def s3_url(path)
          raise Error, 'S3 bucket name is not defined' if Config.s3_bucket.nil?
          path = path.sub(s3_prefix_re, '')
          AWS::S3.new.buckets[Config.s3_bucket].objects[path].url_for(:read)
        end

        # Check if a given path is an S3 path.
        #
        # @param path [String]
        # @return [Boolean]
        def is_s3_path?(path)
          !s3_prefix_re.match(path).nil?
        end

      private
        # A regex generated from {Config.s3_prefix} for determining if a given
        # String is an S3 path.
        #
        # @return [Regexp]
        def s3_prefix_re
          /^#{Config.s3_prefix}\:/
        end
      end
    end
  end
end