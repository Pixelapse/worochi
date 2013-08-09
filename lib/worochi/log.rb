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
      def init_log
        @logger = Logger.new(STDOUT)
        @logger.formatter = proc do |severity, datetime, progname, msg|
          "[\033[#{SEVERITY_COLOR[severity]}m#{severity}\033[0m]: #{msg}\n"
        end
      end

      # Prints DEBUG messages
      def debug(message)
        return if Worochi::Config.silent?
        init_log if @logger.nil?
        @logger.debug message
      end

      # Prints WARN messages
      def warn(message)
        return if Worochi::Config.silent?
        init_log if @logger.nil?
        @logger.warn message
      end

      # Prints INFO messages
      def info(message)
        return if Worochi::Config.silent?
        init_log if @logger.nil?
        @logger.info message
      end

      # Prints ERROR messages
      def error(message)
        return if Worochi::Config.silent?
        init_log if @logger.nil?
        @logger.error message
      end
    end
  end
end