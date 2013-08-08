require 'worochi/config'
require 'worochi/error'
require 'worochi/log'
require 'worochi/helper'
require 'worochi/item'
require 'worochi/agent'

class Worochi
  @agents = []

  class << self
    # List of {Worochi::Agent} waiting for {Worochi.push}.
    #
    # @return [Array]
    attr_reader :agents

    # Creates a new {Worochi::Agent} and adds it to the list of agents
    # listening to {Worochi.push} requests.
    #
    # @param service [Symbol] service name as defined in {Config.services}
    # @param token [String] authorization token for the service API
    # @param opts [Hash] additional service-specific options
    # @return [Worochi::Agent]
    # @see Agent.new
    # @example
    #     Worochi.create(:dropbox, 'as89h38nFBUSHFfuh99f', { dir: '/folder' })
    # @example
    #     opts = {
    #       repo: 'darkmirage/worochi',
    #       source: 'master',
    #       target: 'temp',
    #       commit_msg: 'Hello'
    #     }
    #     Worochi.create(:github, '6st46setsytgbhd64', opts)
    def create(service, token, opts={})
      opts[:service] = service
      opts[:token] = token
      agent = Agent.new(opts)
      @agents << agent
      agent
    end

    # Adds an exist {Worochi::Agent} to the list of agents listening to
    # {Worochi.push} requests.
    #
    # @param agent [Worochi::Agent]
    # @return [nil]
    def add(agent)
      @agents << agent unless @agents.include?(agent)
      nil
    end

    # Remove a specific {Worochi::Agent} from the list of agents listening to
    # {Worochi.push} requests.
    #
    # @param agent [Worochi::Agent]
    # @return [nil]
    def remove(agent)
      @agents.delete(agent)
      nil
    end

    # Remove all agents belonging to a given service from the list. Removes
    # all agents if service is not specified.
    #
    # @param service [Symbol] service name as defined in {Config.services}
    # @return [nil]
    # @see Worochi.reset
    # @example
    #     Worochi.remove(:dropbox)
    def remove_service(service=nil)
      if service.nil?
        reset
      else
        @agents.reject! { |a| a.type == service }
      end
      nil
    end

    # Removes all agents from the list
    #
    # @return [nil]
    def reset
      @agents.clear
    end

    # List the active agents.
    #
    # @return [Array<String>]
    def list
      @agents.map { |a| a.to_s }
    end

    # @return [Integer] number of active agents.
    def size
      @agents.size
    end

    # Push list of files using the active agents in {.agents}. Refer to
    # {Item.open} for how to format the file list.
    #
    # @param origin [Array<Hash>, Array<String>, Hash, String]
    # @param opts [Hash] update agent options before pushing
    # @return [Boolean] success
    # @see Item.open
    # @see Agent#push
    def push(origin, opts={})
      Log.warn 'No push targets specified' and return false if @agents.empty?
      @agents.each { |agent| agent.push(origin, opts) }
      true
    end
  end
end