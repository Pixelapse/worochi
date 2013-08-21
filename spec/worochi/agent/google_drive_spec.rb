require 'spec_helper'

describe Worochi::Agent::GoogleDrive do
  let(:required_keys) { [] }
  let(:client_class) { Google::APIClient }
  let(:folder_id) { '0B30CGkhrN5qzaUJGbFNDRjl0S2M' }

  let(:agent) do
    Worochi::Agent::GoogleDrive.new({
      token: ENV['GOOGLE_TEST_TOKEN'],
      dir: '/worochi/test'
    })
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

  # describe '#delete', :vcr do
  #   it 'deletes a file' do
  #   end
  # end

  describe '#insert_file', :vcr do
    it 'creates a new folder to root' do
      agent.send(:insert_file, 'worochi_insertion_test', folder_id)
      expect(agent.folders).to include('worochi_insertion_test')
    end

    it 'uploads a file' do
      item = Worochi::Item.open_single(local.source)
      agent.send(:insert_file, 'worochi_test.txt', 'root', item)
      expect(agent.files('/')).to include('worochi_test.txt')
    end
  end
end