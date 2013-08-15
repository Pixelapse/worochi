require 'spec_helper'

describe Worochi::Agent::Github do
  let(:required_keys) { [:repo, :source, :target, :block_size, :commit_msg] }
  let(:client_class) { Octokit::Client }
  let(:master_branch) { 'cdddc3941866854cdb41c023d0f5240ed10df053' }

  let(:agent) do
    Worochi::Agent::Github.new({
      token: ENV['GITHUB_TEST_TOKEN'],
      repo: 'darkmirage/test',
      source: 'master',
      target: 'rspec',
      commit_msg: "RSpec Test"
    })
  end

  it_should_behave_like 'a service agent'

  before do
    @client = agent.init_client
  end

  def delete_target
    tag = "heads/#{agent.options[:target]}"
    begin
      @client.delete_ref(agent.options[:repo], tag)
    rescue Octokit::UnprocessableEntity
    end
  end

  describe '#push_all', :vcr do
    it 'pushes a list of items to create a new commit' do
      @client = agent.init_client
      delete_target

      hashes = [remote, local].map do |file|
        { path: file.path, source: file.source }
      end
      items = Worochi::Item.open(hashes)

      sha = agent.push_all(items)
      ref = @client.ref(agent.options[:repo], "heads/#{agent.options[:target]}")
      expect(ref.object.sha).to eq(sha)

      commit = @client.commit(agent.options[:repo], sha)
      expect(commit.commit.message).to eq(agent.options[:commit_msg])

      delete_target
    end

    it 'pushes the file to the right place' do
      delete_target

      item = Worochi::Item.open({ source: local.source, path: local.path })

      sha = agent.push_all(item)
      ls = agent.list(File.dirname(local.path), sha).map { |x| x[:name] }
      expect(ls).to include(local.name)
      
      delete_target
    end
  end

  describe '#stream_blob', :vcr do
    it 'streams the file as an Base64 JSON field' do
      item = Worochi::Item.open_single(path: local.path, source: local.source)
      sha = agent.send(:stream_blob, item)
      expect(sha).to eq('5df468c4497e072139462b88cb78e1df4357534b')
    end
  end

  describe '#source_branch', :vcr do
    it 'retrieves the master branch correctly' do
      expect(agent.send(:source_branch)).to eq(master_branch)
    end
  end

  describe '#list', :vcr do
    it 'works with absolute paths' do
      ls = agent.list('/folder2/subfolder/test').map { |x| x[:name] }
      expect(ls).to include('abc.txt')
    end
  end
end