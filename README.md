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

Pushing files is easy. You just need to create an agent using the OAuth
authorization token for the user and then call {Worochi::Agent#push} or
{Worochi.push}. File origins can be local, HTTP, or Amazon S3 paths.

Pushing files to Dropbox:

    token = '982n3b989az'
    agent = Worochi.create(:dropbox, token)
    agent.push('test.txt')
    agent.files
    # ['test.txt']

Pushing multiple files:

    agent.push(['a.txt', 'folder1/b.txt', 'http://example.com/c.txt'])
    agent.files
    # ['a.txt', 'b.txt', 'c.txt']


Pushing files to more than one agent at the same time:

    a = Worochi.create(:dropbox, 'hxhrerx')
    b = Worochi.create(:dropbox, 'cdgrhdg')
    Worochi.push('test.txt')
    a.files
    # ['test.txt']
    b.files
    # ['test.txt']

Pushing to a specific folder:

    agent = Worochi.create(:dropbox, token, { dir: '/folder1' })
    agent.push('a.txt')

    agent.files
    # ['a.txt']

    agent.set_dir('/')
    agent.push('b.txt')
    agent.files
    # ['b.txt']

    agent.files_and_folders
    # ['folder1', 'b.txt']
    agent.files('/folder1')
    # ['a.txt']


## Development

Each service is implemented as an {Worochi::Agent} object. The behaviors for
each API are defined mainly in two files:

- `/worochi/lib/agent/service_name.rb`
- `/worochi/lib/config/service_name.yml`