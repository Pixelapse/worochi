require 'logger'

class Worochi
  # Implements colored log messages.
  class Log
    # Maps severity level to color code for logging.
    SEVERITY_COLOR = {
      'DEBUG' => 37,
      'INFO' => 32,
      'WARN' => 33,
      'ERROR' => 31,
      'FATAL' => 31
    }
    class << self
      # Initializes the logging system.
      #
      # @param logdev [IO] target device to log to
      def init(logdev=nil)
        @logger = Logger.new(logdev || $stdout)
        @logger.formatter = proc do |severity, datetime, progname, msg|
          "[\033[#{SEVERITY_COLOR[severity]}m#{severity}\033[0m]: #{msg}\n"
        end
      end

      # Prints DEBUG messages
      def debug(message)
        @logger.debug message unless Worochi::Config.silent?
      end

      # Prints WARN messages
      def warn(message)
        @logger.warn message unless Worochi::Config.silent?
      end

      # Prints INFO messages
      def info(message)
        @logger.info message unless Worochi::Config.silent?
      end

      # Prints ERROR messages
      def error(message)
        @logger.error message unless Worochi::Config.silent?
      end
    end
  end
end