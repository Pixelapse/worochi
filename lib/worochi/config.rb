require 'worochi/configurator'

class Worochi
  # Configurations for Worochi.
  module Config
    @s3_enabled = true
    @s3_bucket = 'data-pixelapse'
    @s3_prefix = 's3'
    @silent = true
  end
end
