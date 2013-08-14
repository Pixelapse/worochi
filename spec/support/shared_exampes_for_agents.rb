shared_examples_for 'a service agent' do
  before do
    Worochi.init
  end

  describe '#default_options' do
    it 'has the required options' do
      (required_keys + [:dir, :service]).each do |key|
        expect(agent.send(:default_options)).to include(key)
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

    it 'does not contain folder1' do
      expect(agent.files).not_to include('folder1')
    end
    
    it 'accepts a different relative path' do
      expect(agent.files('folder1')).to include('test.txt')
    end
  end

  describe '#folders', :vcr do
    it 'contains folder1' do
      expect(agent.folders).to include('folder1')
    end

    it 'does not contain file1' do
      expect(agent.folders).not_to include('file1')
    end

    it 'accepts a different relative path' do
      expect(agent.folders('folder1').size).to be(0)
    end
  end

  describe '#files_and_folders', :vcr do
    it 'contains folder1 and file1' do
      expect(agent.files_and_folders).to include('file1')
      expect(agent.files_and_folders).to include('folder1')
    end
  end
end