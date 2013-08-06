require 'aws-sdk' unless Worochi::Config.s3_bucket.nil?

class Worochi
  module Helper
    class << self
      def s3_prefix
        /^#{Config.s3_prefix}\:/
      end

      def s3_url(path)
        raise Error, 'S3 bucket name is not defined' if Config.s3_bucket.nil?
        path = path.sub(s3_prefix, '')
        AWS::S3.new.buckets[Config.s3_bucket].objects[path].url_for(:read)
      end

      def is_s3_path?(path)
        !s3_prefix.match(path).nil?
      end
    end
  end
end