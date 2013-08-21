require 'spec_helper'

describe Worochi::Agent::GoogleDrive do
  let(:required_keys) { [] }
  let(:client_class) { Google::APIClient }
  let(:folder_id) { '0B30CGkhrN5qzaUJGbFNDRjl0S2M' }

  let(:agent) do
    Worochi::Agent::GoogleDrive.new(
      token: ENV['GOOGLE_TEST_TOKEN'],
      dir: '/worochi/test')
  end

  before do
    agent.clear_cache
  end

  it_should_behave_like 'a service agent'

  describe '#get_item_id', :vcr do
    it 'retrieves the item ID' do
      expect(agent.send(:get_item_id, '/worochi/test')).to eq(folder_id)
      # test cache
      expect(agent.send(:get_item_id, '/worochi/test')).to eq(folder_id)
    end
    it 'returns the root ID' do
      expect(agent.send(:get_item_id, '/')).to eq('root')
    end
  end

  describe '#delete', :vcr do
    it 'deletes a file' do
      agent.send(:insert_file, 'to_delete', 'root')
      expect(agent.delete('/to_delete')).to be(true)
    end
    it 'raises error on bad token' do
      bad_agent = Worochi::Agent::GoogleDrive.new(token: 'badtoken')
      expect{bad_agent.delete('test')}.to raise_error(Worochi::Error)
    end
  end

  describe '#push_item', :vcr do
    it 'pushes a single item' do
    end
    it 'creates new directories as needed' do
      item = Worochi::Item.open_single(
        source: local.source,
        path:'aaa/bbb/ccc.txt')
      agent.push_item(item)
      expect(agent.folders).to include('aaa')
      expect(agent.folders('aaa')).to include('bbb')
      expect(agent.files('aaa/bbb')).to include('ccc.txt')
      expect(agent.delete('aaa')).to be(true)
    end

    it 'raises error on bad token' do
      bad_agent = Worochi::Agent::GoogleDrive.new(token: 'badtoken')
      item = Worochi::Item.open_single(local.source)
      expect{bad_agent.push_item(item)}.to raise_error(Worochi::Error)
    end
  end

  describe '#insert_file', :vcr do
    it 'creates a new folder to root' do
      agent.send(:insert_file, 'worochi_insertion_test', folder_id)
      expect(agent.folders).to include('worochi_insertion_test')
      expect(agent.delete('worochi_insertion_test')).to be(true)
    end

    it 'uploads a file' do
      item = Worochi::Item.open_single(
        source: local.source,
        path: 'worochi_test.txt')
      agent.send(:insert_file, item, 'root')
      expect(agent.files('/')).to include('worochi_test.txt')
      expect(agent.delete('/worochi_test.txt')).to be(true)
    end
  end
end