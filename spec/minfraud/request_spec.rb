require 'spec_helper'

describe Minfraud::Request do
  subject(:request) { Minfraud::Request.new(transaction) }
  let(:transaction) { double(Minfraud::Transaction, attributes: {}) }
  let(:success_response) { double(Minfraud::Response, errored?: false, body: '') }
  let(:exception) { Minfraud::ResponseError.new('Message from MaxMind: INVALID_LICENSE_KEY') }

  describe '.new' do
    it 'binds the @transaction instance variable' do
      expect(request.instance_variable_get(:@transaction)).to eql(transaction)
    end
  end

  describe '#get' do
    it 'sends appropriately encoded transaction data to minFraud service' do
      allow(Minfraud).to receive(:license_key?).and_return('6')
      allow(Minfraud::Response).to receive(:new).and_return(success_response)
      trans = Minfraud::Transaction.new do |t|
        t.ip = '1'
        t.city = '2'
        t.state = '3'
        t.postal = '4'
        t.country = '5'
        t.txn_id = '6'
      end
      request_body = {
        'i' => '1',
        'city' => '2',
        'region' => '3',
        'postal' => '4',
        'country' => '5',
        'license_key' => '6'
      }
      http = double(:http)
      expect(Net::HTTP).to receive(:new).and_return(http)
      expect(http).to receive(:use_ssl=).with(true)
      expect(http).to receive(:verify_mode=).with(OpenSSL::SSL::VERIFY_NONE)
      expect(Net::HTTP::Get).to receive(:new)
      expect(http).to receive(:request).and_return(double())
      Minfraud::Request.new(trans).get
    end

    it 'creates Response object out of raw response' do
      expect(request).to receive(:send_get_request)
      expect(Minfraud::Response).to receive(:new).and_return(success_response)
      request.get
    end

    it 'returns Response object' do
      allow(request).to receive(:send_get_request)
      allow(Minfraud::Response).to receive(:new).and_return(success_response)
      expect(request.get).to eql(success_response)
    end

    it 'passes along the host choice' do
      us_east_uri = URI('https://minfraud-us-east.maxmind.com/app/ccv2r')
      allow(Minfraud::Response).to receive(:new).and_return(success_response)
      trans = Minfraud::Transaction.new do |t|
        t.ip = '1'
        t.city = '2'
        t.state = '3'
        t.postal = '4'
        t.country = '5'
        t.txn_id = '6'
        t.host_choice = 'us_east'
      end
      expect(Minfraud).to receive(:uri).with('us_east').and_return(us_east_uri)
      Minfraud::Request.new(trans).get
    end

    it 'sets a timeout on the http connection both read and open when given only a default timeout' do
      http = double(:http).as_null_object # loose double
      expect(Net::HTTP).to receive(:new).and_return(http)
      expect(http).to receive(:read_timeout=).with(3)
      expect(http).to receive(:open_timeout=).with(3)

      trans = Minfraud::Transaction.new do |t|
        t.ip = '1'
        t.city = '2'
        t.state = '3'
        t.postal = '4'
        t.country = '5'
        t.txn_id = '6'
        t.timeout = 3
      end
      Minfraud::Request.new(trans).get
    end

    it 'sets a timeout on the http connection both read and open when given each timeout' do
      http = double(:http).as_null_object # loose double
      expect(Net::HTTP).to receive(:new).and_return(http)
      expect(http).to receive(:read_timeout=).with(4)
      expect(http).to receive(:open_timeout=).with(3)

      trans = Minfraud::Transaction.new do |t|
        t.ip = '1'
        t.city = '2'
        t.state = '3'
        t.postal = '4'
        t.country = '5'
        t.txn_id = '6'
        t.timeout = 2
        t.open_timeout = 3
        t.read_timeout = 4
      end
      Minfraud::Request.new(trans).get
    end
  end

end
