require 'worochi/configurator'

class Worochi
  # Default configurations
  Config.s3_enabled = true
  Config.s3_bucket = 'worochi'
  Config.s3_prefix = 's3'
  Config.silent = true
  Config.logdev = $stdout
end