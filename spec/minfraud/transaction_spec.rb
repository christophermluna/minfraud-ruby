require 'spec_helper'
require 'bigdecimal'

describe Minfraud::Transaction do

  describe 'Minfraud::Transaction.new' do
    it 'yields the current instance module' do
      Minfraud::Transaction.new do |t|
        t.ip = '127.0.0.1'
        t.txn_id = 'Order-1-1'
        t.license_key = 'test_license'
        expect(t).to be_an_instance_of(Minfraud::Transaction)
      end
    end

    it 'raises an exception if required attributes are not set' do
      expect { Minfraud::Transaction.new { |c| true } }.to raise_exception(Minfraud::TransactionError, /required/)
    end

    it 'raises an exception if string attributes are invalid' do
      transaction = lambda do
        Minfraud::Transaction.new do |t|
          t.ip = '127.0.0.1'
          t.txn_id = 'Order-1-1'
          t.license_key = 'test_license'
          t.city = 2
          t.amount = 27.04
          t.state = 'test_state'
        end
      end
      expect { transaction.call }.to raise_exception(Minfraud::TransactionError, /city must be a string/)
    end

    it 'raises an exception if numeric attributes are invalid' do
      transaction = lambda do
        Minfraud::Transaction.new do |t|
          t.ip = '127.0.0.1'
          t.txn_id = 'Order-1-1'
          t.license_key = 'test_license'
          t.amount = 'not_a_number'
          t.state = 'test_state'
        end
      end
      expect { transaction.call }.to raise_exception(Minfraud::TransactionError, /amount must be a number/)
    end

    it 'accepts strings as numbers' do
      Minfraud::Transaction.new do |t|
        t.ip = '127.0.0.1'
        t.txn_id = 'Order-1-1'
        t.license_key = 'test_license'
        t.amount = '27.04'
      end
    end

    it 'accepts BigDecimal inputs for numbers' do
      Minfraud::Transaction.new do |t|
        t.ip = '127.0.0.1'
        t.txn_id = 'Order-1-1'
        t.license_key = 'test_license'
        t.amount = BigDecimal('27.04')
      end
    end

    it 'creates the Transaction properly' do
      Minfraud::Transaction.new do |t|
        t.ip = '127.0.0.1'
        t.txn_id = 'Order-1-1'
        t.license_key = 'test_license'
        t.city = 'test_city'
        t.cvv_result = 'M'
        t.amount = 27.04
      end
    end

    it 'returns an immutable Transaction' do
      transaction = Minfraud::Transaction.new do |t|
        t.ip = '127.0.0.1'
        t.txn_id = 'Order-1-1'
        t.license_key = 'test_license'
      end
      expect(transaction).to be_frozen
    end

    it 'does not raise an exception if billing address is left nil' do
      Minfraud::Transaction.new do |t|
        t.ip = '127.0.0.1'
        t.txn_id = 'Order-1-1'
        t.license_key = 'test_license'
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

    it 'raises an exception if license key is left empty' do
      transaction = lambda do
        Minfraud::Transaction.new do |t|
          t.ip = '127.0.0.1'
          t.txn_id = 'Order-1-1'
          t.license_key = ''
        end
      end
      expect { transaction.call }.to raise_exception(Minfraud::TransactionError, /required/)
    end

    it 'raises an exception if cvv_result is not a single letter' do
      transaction = lambda do
        Minfraud::Transaction.new do |t|
          t.ip = '127.0.0.1'
          t.txn_id = 'Order-1-1'
          t.license_key = 'license_key'
          t.cvv_result = 'AB'
        end
      end
      expect { transaction.call }.to raise_exception(Minfraud::TransactionError, /single letter/)
    end

  end

  describe 'Minfraud::Transaction#attributes' do
    subject(:transaction) do
      Minfraud::Transaction.new do |t|
        t.ip = '127.0.0.1'
        t.txn_id = 'Order-1-1'
        t.license_key = 'test_license'
        t.city = 'city'
        t.state = 'state'
        t.postal = 'postal'
        t.country = 'country'
        t.email = 'hughjass@example.com'
        t.requested_type = 'standard'
        t.shop_id = 'test_shop'
      end
    end

    subject(:transaction_convert_case) do
      Minfraud::Transaction.new do |t|
        t.ip = '127.0.0.1'
        t.txn_id = 'Order-1-1'
        t.license_key = 'test_license'
        t.email = 'HUGHjass@examPLE.COM'
      end
    end

    subject(:transaction_shop_id_int) do
      Minfraud::Transaction.new do |t|
        t.ip = '127.0.0.1'
        t.txn_id = 'Order-1-1'
        t.license_key = 'test_license'
        t.shop_id = 123456789
      end
    end

    it 'returns a hash of attributes' do
      expect(transaction.attributes[:ip]).to eq('127.0.0.1')
      expect(transaction.attributes[:txn_id]).to eq('Order-1-1')
      expect(transaction.attributes[:license_key]).to eq('test_license')
      expect(transaction.attributes[:city]).to eq('city')
      expect(transaction.attributes[:state]).to eq('state')
      expect(transaction.attributes[:postal]).to eq('postal')
      expect(transaction.attributes[:country]).to eq('country')
    end

    it 'derives email domain and an MD5 hash of whole email from email attribute' do
      expect(transaction.attributes[:email_domain]).to eq('example.com')
      expect(transaction.attributes[:email_md5]).to eq('01ddb59d9bc1d1bfb3eb99a22578ce33')
    end

    it 'converts the email to lowercase when calculating its MD5 hash' do
      expect(transaction_convert_case.attributes[:email_domain]).to eq('examPLE.COM')
      expect(transaction_convert_case.attributes[:email_md5]).to eq('01ddb59d9bc1d1bfb3eb99a22578ce33')
    end

    it 'converts the shop_id from int to string' do
      expect(transaction_shop_id_int.attributes[:shop_id]).to eq('123456789')
    end

  end

end
