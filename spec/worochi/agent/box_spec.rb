require 'spec_helper'

describe Worochi::Agent::Box, :box do
  let(:required_keys) { [] }
  let(:client_class) { RubyBox::Client }

  let(:agent) do
    Worochi::Agent::Box.new(
      token: ENV['BOX_TEST_TOKEN'],
      dir: '/worochi/test')
  end

  it_should_behave_like 'a service agent'

  describe '#push_item', :vcr do
    it 'pushes a single item' do
      item = Worochi::Item.open_single(local.source)
      agent.push_item(item)
      expect(agent.files).to include(local.name)
      agent.delete(local.name)
      expect(agent.files).not_to include(local.name)
    end  
  end

  describe '#box_error', :vcr do
    it 'raises an error on expired/invalid tokens' do
      bad_agent = Worochi::Agent::Box.new(token: 'badtoken')
      expect{bad_agent.files}.to raise_error(Worochi::Error)
      item = Worochi::Item.open_single(local.source)
      expect{bad_agent.push_item(item)}.to raise_error(Worochi::Error)
      expect{bad_agent.delete(local.name)}.to raise_error(Worochi::Error)
    end
  end
end