class Worochi
  # Contains any global helper methods not specific to any individual service.
  module Helper
    class << self
      # Given an S3 path, return the full URL for the corresponding object
      # determined using the AWS SDK. AWS_SECRET_ACCESS_KEY and
      # AWS_ACCESS_KEY_ID should be present in ENV. The string should be
      # formatted as: `s3:(bucket_name:)path/to/file`.
      #
      # @param path [String] S3 path
      # @return [URI::HTTPS] URI of the file on S3
      # @example Pre-configured bucket name
      #   Worochi::Config.s3_bucket = 'worochi'
      #   Worochi::Helper.s3_url('s3:test/path')
      #   # => #<URI::HTTPS URL:https://worochi.s3.amazonaws.com/test/path?AWSAccessKeyId=...>
      # @example Custom bucket name
      #   Worochi::Helper.s3_url('s3:bucket-name:a/b')
      #   # => #<URI::HTTPS URL:https://bucket-name.s3.amazonaws.com/a/b?AWSAccessKeyId=...>
      # @example Invalid syntax
      #   Worochi::Helper.s3_url('www.a.com/b.txt')
      #   # => Worochi::Error
      def s3_url(path)
        raise Error, 'Invalid S3 path' unless is_s3_path?(path)
        path = path.sub(s3_prefix_re, '')
        if match = /^(.*)\:/.match(path)
          bucket = match[1]
          path = path.sub(/^(.*)\:/, '')
        end
        bucket ||= Config.s3_bucket
        raise Error, 'S3 bucket name is not defined' if bucket.nil?
        AWS::S3.new.buckets[bucket].objects[path].url_for(:read)
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

# Load all helpers
Dir[File.join(File.dirname(__FILE__), 'helper/[^#]*.rb')].each do |file|
  require 'worochi/helper/' + File.basename(file, '.rb')
end