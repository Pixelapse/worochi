require 'oauth2'

class Worochi
  # Implements OAuth2 authorization code flow for obtaining user tokens.
  class OAuth
    # List of options that should not be sent with HTTP requests.
    INTERNAL_OPTS = [:id_env, :secret_env, :token_url, :authorize_url, :site,
      :token_site, :service]

    # OAuth2 options.
    # @return [Hashie::Mash]
    attr_accessor :options

    # The OAuth2 client
    # @return [OAuth2::Client]
    attr_reader :client

    # @param service [Symbol] service name
    # @param redirect_uri [String] callback URL if required
    def initialize(service, redirect_uri=nil)
      @options = Worochi::Config.service_opts(service).oauth
      options.service = service
      options.redirect_uri = redirect_uri
      opts = { site: options.site }
      opts[:authorize_url] = options.authorize_url if options.authorize_url
      opts[:token_url] = options.token_url if options.token_url
      @client = OAuth2::Client.new(id, secret, opts)
    end

    # Returns the URL to start the authorization flow.
    #
    # @param state [String] optional security verification state
    # @return [String] URL to begin flow
    def flow_start(state=nil)
      client.site = options.site
      opts = params
      opts[:state] = state if state
      client.auth_code.authorize_url(opts)
    end

    # Retrieves the token using the temporary authorization code.
    #
    # @param code [String] authorization code from the first part
    # @return [Hashie::Mash] OAuth2 token
    def flow_end(code)
      client.site = options.token_site || options.site
      opts = {}
      opts[:redirect_uri] = options.redirect_uri if options.redirect_uri
      Hashie::Mash.new(client.auth_code.get_token(code, opts).to_hash)
    end

    # Refreshes an existing access token using the refresh token.
    #
    # @param hash [Hash] stored hash for the token
    # @return [Hashie::Mash] Updated OAuth2 token
    def refresh(hash)
      token = OAuth2::AccessToken.from_hash(@client, hash)
      begin
        Hashie::Mash.new(token.refresh!.to_hash)
      rescue OAuth2::Error
        raise Worochi::Error, 'Invalid refresh token'
      end
    end

    alias_method :get_token, :flow_end

  private
    # @return [Hash] returns only the options that are meant to be sent.
    def params
      options.reject { |k, v| INTERNAL_OPTS.include?(k.to_sym) }
    end

    # @return [String] scope
    def scope
      options.scope || ''
    end

    # @return [String] environmental variable for client ID
    def id
      var = options.id_env || options.service.to_s.upcase + '_ID'
      ENV[var]
    end

    # @return [String] environmental variable for client secret
    def secret
      var = options.secret_env || options.service.to_s.upcase + '_SECRET'
      ENV[var]
    end
  end
end