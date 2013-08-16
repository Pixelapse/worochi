require 'bundler'
require 'rubygems'
Bundler.setup
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

task default: :spec
task test: :spec

task :yard do
  begin
    require 'yard'
    YARD::Rake::YardocTask.new do |task|
      task.files   = ['lib/**/*.rb']
      task.options = [
        '--output-dir', 'doc',
        '--markup', 'markdown',
      ]
    end
  rescue LoadError
  end
end

task doc: :yard