require 'spec_helper'

describe Worochi::Agent::Github, :github do
  let(:required_keys) { [:repo, :source, :target, :block_size, :commit_msg] }
  let(:client_class) { Octokit::Client }
  let(:master_branch) { 'cdddc3941866854cdb41c023d0f5240ed10df053' }

  let(:agent) do
    Worochi::Agent::Github.new(
      token: ENV['GITHUB_TEST_TOKEN'],
      repo: 'darkmirage/test',
      source: 'master',
      target: 'rspec',
      commit_msg: "RSpec Test")
  end

  it_should_behave_like 'a service agent'

  context 'modifies the repo' do
    before do
      @client = agent.init_client
      @item = Worochi::Item.open_single(
        path: local.path,
        source: local.source)
      delete_target
    end

    after do
      delete_target
    end

    def delete_target
      tag = "heads/#{agent.options[:target]}"
      begin
        @client.delete_ref(agent.options[:repo], tag)
      rescue Octokit::UnprocessableEntity
      end
    end

    def ref
      @client.ref(agent.options[:repo], "heads/#{agent.options[:target]}")
    end

    describe '#push_all', :vcr do
      it 'pushes a list of items to create a new commit' do
        hashes = [remote, local].map do |file|
          { path: file.path, source: file.source }
        end
        items = Worochi::Item.open(hashes)

        sha = agent.push_all(items)
        expect(ref.object.sha).to eq(sha)

        commit = @client.commit(agent.options[:repo], sha)
        expect(commit.commit.message).to eq(agent.options[:commit_msg])
      end

      it 'pushes the file to the right place' do
        sha = agent.push_all([@item])
        ls = agent.list(File.dirname(local.path), sha).map { |x| x[:name] }
        expect(ls).to include(local.name)
      end
    end

    describe '#push_item', :vcr do
      it 'pushes a single item and makes a commit' do
        sha = agent.push_item(@item)
        expect(ref.object.sha).to eq(sha)
      end
    end

    describe '#stream_blob', :vcr do
      it 'streams the file as an Base64 JSON field' do
        sha = agent.send(:stream_blob, @item)
        expect(sha).to eq('5df468c4497e072139462b88cb78e1df4357534b')
      end
    end

    describe '#push_blob', :vcr do
      it 'pushes the blob even when it is larger than block size' do
        agent.options.block_size = 2
        sha = agent.send(:push_blob, @item)
        expect(sha).to eq('5df468c4497e072139462b88cb78e1df4357534b')
      end
    end
  end

  describe '#source_branch', :vcr do
    it 'retrieves the master branch correctly' do
      expect(agent.send(:source_branch)).to eq(master_branch)
    end
  end

  describe '#repos', :vcr do
    it 'lists the repos' do
      expect(agent.repos).to include('darkmirage/test')
    end
  end

  describe '#list', :vcr do
    it 'works with absolute paths' do
      ls = agent.list('/folder2/subfolder/test').map { |x| x[:name] }
      expect(ls).to include('abc.txt')
    end
  end

  describe '#delete' do
    it 'does not allow file deletion' do
      expect{agent.delete('test')}.to raise_error(Worochi::Error)
    end
  end
end