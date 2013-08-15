lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'worochi/version'

Gem::Specification.new do |s|
  s.name = 'worochi'
  s.version = Worochi::VERSION
  s.date = '2013-08-02'
  s.summary = 'Worochi'
  s.description = 'Provides a standard way to interface with Ruby API wrappers provided by various cloud storage services such as Dropbox and Google Drive.'

  s.authors = ['Raven Jiang']
  s.email = ['raven@cs.stanford.edu']
  s.homepage = 'https://github.com/Pixelapse/worochi'
  s.license = 'MIT'

  s.files = %w(README.md LICENSE worochi.gemspec)
  s.files += Dir.glob('lib/**/*.{rb,yml}')
  s.test_files = Dir.glob('spec/**/*')

  s.require_paths = ['lib']

  s.add_runtime_dependency('hashie')
  s.add_runtime_dependency('oauth2')
  s.add_runtime_dependency('aws-sdk')
  s.add_runtime_dependency('dropbox-sdk') # Dropbox
  s.add_runtime_dependency('octokit') # GitHub

  s.add_development_dependency('rspec', ['~> 2.14.1'])
  s.add_development_dependency('vcr', ['~> 2.5.0'])
  s.add_development_dependency('webmock', ['~> 1.9.3'])
  s.add_development_dependency('awesome_print')
  s.add_development_dependency('yard')
  s.add_development_dependency('simplecov')
  s.add_development_dependency('coveralls')

  s.post_install_message = <<-MESSAGE
  Worochi says, "RAWRRRRR!!!"
  MESSAGE
end
