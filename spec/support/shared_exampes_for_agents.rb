shared_examples_for 'a service agent' do
  describe '#default_options' do
    it 'has the required options' do
      agent.default_options.include?(:dir).should be_true
      agent.default_options.include?(:service).should be_true
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