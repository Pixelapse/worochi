Gem::Specification.new do |s|
  s.name = 'worochi'
  s.version = '0.0.0'
  s.date = '2013-08-02'
  s.summary = 'Worochi'
  s.description = 'Provides a standard way to interface with Ruby API wrappers provided by various cloud storage services such as Dropbox and Google Drive.'
  s.authors = ['Raven Jiang']
  s.email = ['raven@cs.stanford.edu']
  s.files = %w(README.md worochi.gemspec)
  s.files += Dir.glob('lib/**/*.rb')
  s.require_paths = ["lib"]
  s.homepage = 'http://rubygems.org/gems/worochi'
  s.license = 'MIT'
end
