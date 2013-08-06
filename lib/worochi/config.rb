class Worochi
  module Config
    @services = [:github, :dropbox]
    @s3_bucket = 'data-pixelapse'
    @s3_prefix = 's3'

    class << self
      attr_reader :services, :s3_bucket, :s3_prefix
    end
  end
end

