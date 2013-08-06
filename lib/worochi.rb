require 'worochi/config'
require 'worochi/error'
require 'worochi/log'
require 'worochi/helper'
require 'worochi/item'
require 'worochi/agent'

class Worochi
  @agents = []

  class << self
    attr_reader :agents

    def create(service, token, opts={})
      opts[:service] = service
      opts[:token] = token
      agent = Agent.new(opts)
      @agents << agent
      agent
    end

    def add(agent)
      @agents << agent
    end

    def remove(agent)
      @agents.delete(agent)
    end

    def remove_service(service=nil)
      if service.nil?
        reset
      else
        @agents.reject! { |a| a.type == service }
      end
    end

    def reset
      @agents.clear
    end

    def list
      @agents.each { |a| a.to_s }
    end

    def size
      @agents.size
    end

    def push(origin, opts={})
      Log.warn 'No push targets specified' and return false if @agents.empty?
      items = Item.open(origin)
      @agents.each { |agent| agent.push(items, opts) }
      true
    end
  end
end