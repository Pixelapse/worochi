class Worochi
  class Agent::Sample < Agent

    # General agent methods

    def default_options
      {
        dir: '/'
      }
    end

    def init_client
      @client = nil
    end

    def push_all(items)
    end

    def push_file(item)
    end

    def folders
    end

    # Service specific methods
  end
end