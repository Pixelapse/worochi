# Worochi

![Coverage Status](https://coveralls.io/repos/Pixelapse/worochi/badge.png?branch=master)

Worochi provides a standard way to interface with Ruby API wrappers provided
by various cloud storage services such as Dropbox and Google Drive.

## Installation

Worochi can be installed as a gem.

    gem install worochi

## Documentation

[http://rdoc.info/gems/worochi][documentation]

[documentation]: http://rdoc.info/gems/worochi

## Basic Usage

Pushing files is easy. Just create an agent using the OAuth authorization
token for the user and then call {Worochi::Agent#push} or {Worochi.push}. File
origins can be local, HTTP, or Amazon S3 paths.

Pushing files to Dropbox:

```ruby
token = '982n3b989az'
agent = Worochi.create(:dropbox, token)
agent.push('test.txt')
agent.files
# => ['test.txt']
```

Pushing multiple files:

```ruby
agent.push(['a.txt', 'folder1/b.txt', 'http://example.com/c.txt'])
agent.files
# => ['a.txt', 'b.txt', 'c.txt']
```

Pushing files to more than one agent at the same time:

```ruby
a = Worochi.create(:dropbox, 'hxhrerx')
b = Worochi.create(:dropbox, 'cdgrhdg')
Worochi.push('test.txt')
a.files
# => ['test.txt']
b.files
# => ['test.txt']
```

Pushing to a specific folder:

```ruby
agent = Worochi.create(:dropbox, token, { dir: '/folder1' })
agent.push('a.txt')

agent.files
# => ['a.txt']

agent.set_dir('/')
agent.push('b.txt')
agent.files
# => ['b.txt']

agent.files_and_folders
# => ['folder1', 'b.txt']
agent.files('/folder1')
# => ['a.txt']
```

## Amazon S3 Support

Files can be retrieved directly from their Amazon S3 location either using the
bucket name specified in the configuration or by specifiying a bucket name in
the path.

```ruby
Worochi::Config.s3_bucket = 'rawr'

agent.push('s3:path/to/file')
# Retrieves from https://rawr.s3.amazonaws.com/path/to/file?AWSAccessKeyId=...

agent.push('s3:pikachu:path/to/file')
# Retrieves from https://pikachu.s3.amazonaws.com/path/to/file?AWSAccessKeyId=...
```

This uses Amazon's Ruby SDK to create a presigned URL for the specified file
and then retrieves the file over HTTPS. `AWS_ACCESS_KEY_ID` and
`AWS_SECRET_ACCESS_KEY` should be present in your environmental variables for
this to work.

## OAuth2 Flow

Worochi provides helper methods to assist with the OAuth2 authorization flow.

Example Rails controller:

```ruby
class ApiTokensController < ApplicationController

  # GET /worochi/token/new/:service
  def create
    session[:oauth_flow_state] = state = SecureRandom.hex
    redirect_to oauth.flow_start(state)
  end

  # GET /worochi/token/callback/:service
  def callback
    raise Error unless session[:oauth_flow_state] == params[:state]
    token = oauth.flow_end(params[:code])
    # token is a hash containing the retrieved access token
  end

private

  def oauth
    service = params[:service].to_sym
    redirect_url = oauth_callback_url(service) # defined in routes.rb
    Worochi::OAuth.new(service, redirect_url)
  end
end
```

Service-specific settings for OAuth2 are predefined in the gem, so the
framework just needs to handle verification of session state (this is usually
optional) and storing the retrieved access token value.

## Development

Each service is implemented as an {Worochi::Agent} object. Below is an
overview of the files necessary for defining an agent to support a new
service.

The behaviors for each API are defined mainly in two files:

    /worochi/lib/agent/foo_bar.rb
    /worochi/lib/config/foo_bar.yml

Optional helper file:

    /worochi/lib/helper/foo_bar_helper.rb

Test file:

    /worochi/spec/worochi/agent/foo_bar_spec.rb

Use underscore for filenames and corresponding mixed case for class name. The
class name and service name symbol for the above example would be:

```ruby
class Worochi::Agent::FooBar < Worochi::Agent
end

Worochi.create(:foo_bar, token)
```

RSpec tests use the [VCR](https://github.com/vcr/vcr) gem to record and
playback real HTTP interactions. Remember to filter out API tokens in the
recordings.

## Name

Worochi is the archaic spelling of
[Orochi](http://en.wikipedia.org/wiki/Yamata_no_Orochi), a mythical
eight-headed serpent in Japanese mythology.

