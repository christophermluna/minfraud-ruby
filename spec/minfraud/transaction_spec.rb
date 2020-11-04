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
          t.license_key = ''
        end
      end
      expect { transaction.call }.to raise_exception(Minfraud::TransactionError, /city must be a string/)
    end

    it 'does not raise an exception if billing address is left nil' do
      Minfraud::Transaction.new do |t|
        t.ip = '127.0.0.1'
        t.txn_id = 'Order-1-1'
        t.license_key = ''
      end
    end

    it 'raises an exception if license key is left nil' do
      transaction = lambda do
        Minfraud::Transaction.new do |t|
          t.ip = '127.0.0.1'
          t.txn_id = 'Order-1-1'
        end
      end
      expect { transaction.call }.to raise_exception(Minfraud::TransactionError, /required/)
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
        t.license_key = ''
      end
    end

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

end
