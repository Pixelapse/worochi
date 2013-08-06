require 'logger'

class Worochi
  class Log
    SEVERITY_COLOR = {
      'DEBUG' => 37,
      'INFO' => 32,
      'WARN' => 33,
      'ERROR' => 31,
      'FATAL' => 31
    }
    class << self
      def init_log
        @logger = Logger.new(STDOUT)
        @logger.formatter = proc do |severity, datetime, progname, msg|
          "[\033[#{SEVERITY_COLOR[severity]}m#{severity}\033[0m]: #{msg}\n"
        end
      end

      def debug(message)
        init_log if @logger.nil?
        @logger.debug message
      end

      def warn(message)
        init_log if @logger.nil?
        @logger.warn message
      end

      def info(message)
        init_log if @logger.nil?
        @logger.info message
      end

      def error(message)
        init_log if @logger.nil?
        @logger.error message
      end
    end
  end
end