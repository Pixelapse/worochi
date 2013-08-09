# Allows of matching of dynamic AWS addresses for playback
VCR.configure do |c|
  c.register_request_matcher :uri_aws do |x, y|
    next true if x.uri == y.uri
    next false unless x.uri.include?('amazonaws.com')
    URI(x.uri).path == URI(y.uri).path
  end

  c.default_cassette_options = {
    match_requests_on: [:method, :uri_aws]
  }
end