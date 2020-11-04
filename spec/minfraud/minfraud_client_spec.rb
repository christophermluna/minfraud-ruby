require 'spec_helper'
require 'webmock/rspec'

describe Minfraud::MinfraudClient do
  subject(:minfraud_client) {
    Minfraud::MinfraudClient.new(host_choice: base_url)
  }
  let(:transaction) { double(Minfraud::Transaction, attributes: {}) }
  let(:success_response) { double(Minfraud::Response, code: 200, body: '') }

  describe '.new' do
    it 'creates a new Faraday Connection' do
      expect(minfraud_client.instance_variable_get(:@http_client)).to be_instance_of(Faraday::Connection)
    end
  end

  describe '#send_transaction' do
    it 'sends appropriately encoded transaction data to minFraud service' do
      allow(Minfraud::Response).to receive(:new).and_return(success_response)
      stub_request(:get, request_url)
        .with(query: hash_including({})) # ignores query parameters
        .to_return(status: 200, body: '')

      transaction = Minfraud::Transaction.new do |t|
        t.ip = '1'
        t.city = '2'
        t.state = '3'
        t.postal = '4'
        t.country = '5'
        t.txn_id = '6'
        t.license_key = '7'
      end

      minfraud_client.send_transaction(transaction: transaction, url: endpoint_url)

      expect(a_request(:get, request_url).with(
        query: hash_including({
          'i': '1',
          'city': '2',
          'region': '3',
          'postal': '4',
          'country': '5',
          'txnID': '6',
          'license_key': '7',
        })
      )).to have_been_made
    end

    it 'sends request using a persisted connection' do
      allow(Minfraud::Response).to receive(:new).and_return(success_response)
      stub_request(:get, request_url)
        .with(query: hash_including({})) # ignores query parameters
        .to_return(status: 200, body: '')

      minfraud_client.send_transaction(transaction: transaction, url: endpoint_url)

      expect(a_request(:get, request_url).with(
        headers: { 'Connection' => 'keep-alive' }
      )).to have_been_made
    end

    it 'sends request to the right service host' do
      minfraud_client = Minfraud::MinfraudClient.new(host_choice: 'us_east')
      allow(Minfraud::Response).to receive(:new).and_return(success_response)
      stub_request(:get, 'https://minfraud-us-east.maxmind.com/app/ccv2r')
        .with(query: hash_including({})) # ignores query parameters
        .to_return(status: 200, body: '')

      minfraud_client.send_transaction(transaction: transaction, url: endpoint_url)

      expect(a_request(:get, 'https://minfraud-us-east.maxmind.com/app/ccv2r')).to have_been_made
    end

    it 'raises a ConnectionException if there is an HTTP error' do
      allow(Minfraud::Response).to receive(:new).and_return(success_response)
      stub_request(:get, request_url)
        .with(query: hash_including({})) # ignores query parameters
        .to_raise(Errno::ECONNREFUSED)

      expect {
        minfraud_client.send_transaction(transaction: transaction, url: endpoint_url)
      }.to raise_error(Minfraud::ConnectionException)
    end

    it 'creates Response object out of raw response' do
      expect(minfraud_client.instance_variable_get(:@http_client)).to receive(:get)
      expect(Minfraud::Response).to receive(:new).and_return(success_response)
      minfraud_client.send_transaction(transaction: transaction, url: endpoint_url)
    end
  end

  def base_url
    'https://minfraud.maxmind.com'
  end

  def endpoint_url
    '/app/ccv2r'
  end

  def request_url
    'https://minfraud.maxmind.com/app/ccv2r'
  end

end
