shared_examples_for 'a service agent' do
  describe '#default_options' do
    it 'has the required options' do
      (required_keys + [:dir, :service]).each do |key|
        expect(agent.default_options).to include(key)
      end
    end
  end

  describe '#init_client' do
    it 'returns the client' do
      client = agent.init_client
      expect(client.class).to be(client_class)
    end
  end

  describe '#files', :vcr do
    it 'contains file1' do
      expect(agent.files).to include('file1')

    end
  end

  describe '#folders', :vcr do
    it 'contains folder1' do
      expect(agent.folders).to include('folder1')
    end
  end
end