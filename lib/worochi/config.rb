require 'worochi/configurator'

class Worochi
  # Configurations for Worochi.
  module Config
    @services = [:github, :dropbox]
    @s3_bucket = 'data-pixelapse'
    @s3_prefix = 's3'
    @silent = true
  end
end
