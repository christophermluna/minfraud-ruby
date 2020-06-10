require 'spec_helper'

describe Minfraud::Transaction do

  describe '.new' do
    it 'yields the current instance module' do
      Minfraud::Transaction.new do |t|
        allow(t).to receive(:has_required_attributes?).and_return(true)
        allow(t).to receive(:validate_attributes).and_return(nil)
        expect(t).to be_an_instance_of(Minfraud::Transaction)
      end
    end

    it 'raises an exception if required attributes are not set' do
      expect { Minfraud::Transaction.new { |c| true } }.to raise_exception(Minfraud::TransactionError, /required/)
    end

    it 'raises an exception if attributes are invalid' do
      transaction = lambda do
        Minfraud::Transaction.new do |t|
          t.ip = ''
          t.city = 2
          t.state = ''
          t.postal = ''
          t.country = ''
          t.txn_id = ''
        end
      end
      expect { transaction.call }.to raise_exception(Minfraud::TransactionError, /city must be a string/)
    end

    it 'does not raise an exception if billing address is left nil' do
      Minfraud::Transaction.new do |t|
        t.ip = '127.0.0.1'
        t.txn_id = 'Order-1-1'
      end
    end
  end

  describe '#risk_score' do
    subject(:transaction) do
      Minfraud::Transaction.new do |t|
        allow(t).to receive(:has_required_attributes?).and_return(true)
        allow(t).to receive(:validate_attributes).and_return(nil)
      end
    end
    let(:response) { double(risk_score: risk_score) }
    let(:risk_score) { 3.4 }

    before do
      allow(Minfraud::Request).to receive(:get).and_return(response)
    end

    context 'transaction has not already been sent to MaxMind' do
      it 'sends transaction to MaxMind' do
        expect(Minfraud::Request).to receive(:get).with(transaction)
        transaction.risk_score
      end

      it 'caches response' do
        transaction.risk_score
        expect(transaction.instance_variable_get(:@response)).to eql(response)
        expect(transaction.response).to eql(response)
      end

      it 'returns float containing risk score' do
        transaction.risk_score
        expect(transaction.risk_score).to eq(risk_score)
      end
    end

    context 'transaction has already been sent to MaxMind' do
      before { transaction.instance_variable_set(:@response, response) }

      it 'does not send transaction to MaxMind' do
        expect(Minfraud::Request).not_to receive(:get)
        transaction.risk_score
      end

      it 'returns float containing risk score' do
        expect(transaction.risk_score).to eq(risk_score)
      end
    end
  end

  describe '#attributes' do
    subject(:transaction) do
      Minfraud::Transaction.new do |t|
        t.ip = 'ip'
        t.city = 'city'
        t.state = 'state'
        t.postal = 'postal'
        t.country = 'country'
        t.email = 'hughjass@example.com'
        t.txn_id = 'Order-1'
        t.requested_type = 'standard'
      end
    end

    before { Minfraud.requested_type = 'premium' }
    after { Minfraud.remove_class_variable(:@@requested_type) }

    it 'returns a hash of attributes' do
      expect(transaction.attributes[:ip]).to eq('ip')
      expect(transaction.attributes[:city]).to eq('city')
      expect(transaction.attributes[:state]).to eq('state')
      expect(transaction.attributes[:postal]).to eq('postal')
      expect(transaction.attributes[:country]).to eq('country')
    end

    it 'derives email domain and an md5 hash of whole email from email attribute' do
      expect(transaction.attributes[:email_domain]).to eq('example.com')
      expect(transaction.attributes[:email_md5]).to eq('01ddb59d9bc1d1bfb3eb99a22578ce33')
    end

  end

  describe '#requested_type' do
    subject(:transaction) do
      Minfraud::Transaction.new do |t|
        t.ip = 'ip'
        t.city = 'city'
        t.state = 'state'
        t.postal = 'postal'
        t.country = 'country'
        t.email = 'hughjass@example.com'
        t.txn_id = 'Order-1'
        t.requested_type = 'standard'
      end
    end

    before { Minfraud.requested_type = 'premium' }
    after { Minfraud.remove_class_variable(:@@requested_type) }

    it 'uses requested type as set on transaction if present' do
      expect(transaction.attributes[:requested_type]).to eq('standard')
    end

    it 'uses requested type as set during configuration if not present in transaction' do
      transaction = Minfraud::Transaction.new do |t|
        t.ip = 'ip'
        t.city = 'city'
        t.state = 'state'
        t.postal = 'postal'
        t.country = 'country'
        t.email = 'hughjass@example.com'
        t.txn_id = 'Order-1'
      end
      expect(transaction.attributes[:requested_type]).to eq('premium')
    end

  end

  describe "#timeout=" do
    it 'raises an ArgumentError if a numeric value is not provided' do
      transaction = Minfraud::Transaction.new do |t|
        t.ip = 'ip'
        t.city = 'city'
        t.state = 'state'
        t.postal = 'postal'
        t.country = 'country'
        t.email = 'hughjass@example.com'
        t.txn_id = 'Order-1'
      end
      expect { transaction.timeout = "2.0" }.to raise_exception(ArgumentError, /Timeout value must be Numeric/)
    end
  end

  describe "#open_timeout=" do
    it 'raises an ArgumentError if a numeric value is not provided' do
      transaction = Minfraud::Transaction.new do |t|
        t.ip = 'ip'
        t.city = 'city'
        t.state = 'state'
        t.postal = 'postal'
        t.country = 'country'
        t.email = 'hughjass@example.com'
        t.txn_id = 'Order-1'
      end
      expect { transaction.open_timeout = "1.0" }.to raise_exception(
        ArgumentError,
        /Open timeout value must be Numeric/
      )
    end
  end

  describe "#read_timeout=" do
    it 'raises an ArgumentError if a numeric value is not provided' do
      transaction = Minfraud::Transaction.new do |t|
        t.ip = 'ip'
        t.city = 'city'
        t.state = 'state'
        t.postal = 'postal'
        t.country = 'country'
        t.email = 'hughjass@example.com'
        t.txn_id = 'Order-1'
      end
      expect { transaction.read_timeout = "3.0" }.to raise_exception(
        ArgumentError,
        /Read timeout value must be Numeric/
      )
    end
  end

end
