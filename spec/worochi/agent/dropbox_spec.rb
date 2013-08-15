require 'spec_helper'

describe Worochi::Agent::Dropbox do
  let(:required_keys) { [:chunk_size, :overwrite] }
  let(:client_class) { DropboxClient }

  let(:agent) do
    Worochi::Agent::Dropbox.new({
      token: ENV['DROPBOX_TEST_TOKEN'],
      dir: '/Dev/test'
    })
  end

  it_should_behave_like 'a service agent'

  describe '#push_item', :vcr do
    def push_single
      agent.delete(local.name)
      expect(agent.files).not_to include(local.name)

      item = Worochi::Item.open_single(local.source)
      chunked = agent.push_item(item)
      
      expect(agent.files).to include(local.name)
      agent.delete(local.name)
      chunked
    end

    it 'pushes a single item' do
      expect(push_single).to be(false)
    end
    it 'pushes it chunked if size exceeds limit', :vcr do
      agent.options.chunk_size = 4
      expect(push_single).to be(true)
    end
  end

  describe '#push_items', :vcr do
    it 'pushes multiple items' do
      items = Worochi::Item.open([local.source, local.source])
      expect(agent.push_items(items)).to be(nil)
      agent.delete(local.name)
    end
  end

  describe '#push_item_chunked', :vcr do
    it 'pushes a single item in chunks' do
      agent.delete(local.name)
      expect(agent.files).not_to include(local.name)

      item = Worochi::Item.open_single(local.source)
      agent.push_item_chunked(item)
      
      expect(agent.files).to include(local.name)
      agent.delete(local.name)
    end

    it 'raises an error' do
      bad_agent = Worochi::Agent::Dropbox.new({
        token: 'badtoken',
        dir: '/Dev/test'
      })
      item = Worochi::Item.open_single(local.source)
      expect{bad_agent.push_item_chunked(item)}.to raise_error Worochi::Error
    end
  end

  describe '#list', :vcr do
    it 'works with absolute paths' do
      ls = agent.list('/Dev/test/folder2/subfolder/test').map { |x| x[:name] }
      expect(ls).to include('abc.txt')
    end
  end
end