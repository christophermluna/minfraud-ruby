require 'net/http'
require 'openssl'
require 'faraday'

module Minfraud

  class MinfraudClient

    DEFAULT_OPEN_TIMEOUT = 1
    DEFAULT_IDLE_TIMEOUT = 5
    DEFAULT_READ_TIMEOUT = 5
    DEFAULT_WRITE_TIMEOUT = 5
    DEFAULT_POOL_SIZE = 10

    FIELD_MAP = {
      ip: 'i',
      city: 'city',
      state: 'region',
      postal: 'postal',
      country: 'country',
      license_key: 'license_key',
      ship_addr: 'shipAddr',
      ship_city: 'shipCity',
      ship_state: 'shipRegion',
      ship_postal: 'shipPostal',
      ship_country: 'shipCountry',
      email_domain: 'domain',
      email_md5: 'emailMD5',
      phone: 'custPhone',
      bin: 'bin',
      session_id: 'sessionID',
      user_agent: 'user_agent',
      accept_language: 'accept_language',
      txn_id: 'txnID',
      amount: 'order_amount',
      currency: 'order_currency',
      txn_type: 'txn_type',
      avs_result: 'avs_result',
      cvv_result: 'cvv_result',
      requested_type: 'requested_type',
      forwarded_ip: 'forwardedIP',
      shop_id: 'shopID'
    }

    # @param url [String] String base URL
    # @param open_timeout [Numeric] Seconds to wait for a connection to be opened
    # @param idle_timeout [Numeric] Seconds before automatically be resetting an unused connection
    # @param read_timeout [Numeric] Seconds to wait until reading one block
    # @param write_timeout [Numeric] Seconds to wait until writing one block
    # @param pool_size [Numeric] Maximum number of connections allowed
    def initialize(
      host_choice: DEFAULT_HOST,
      open_timeout: DEFAULT_OPEN_TIMEOUT,
      idle_timeout: DEFAULT_IDLE_TIMEOUT,
      read_timeout: DEFAULT_READ_TIMEOUT,
      write_timeout: DEFAULT_WRITE_TIMEOUT,
      pool_size: DEFAULT_POOL_SIZE
    )
      url = SERVICE_HOSTS[host_choice] || host_choice
      @http_client = Faraday.new(url: url) do |f|
        f.adapter(:net_http_persistent, pool_size: pool_size) do |http|
          http.open_timeout = open_timeout
          http.idle_timeout = idle_timeout
          http.read_timeout = read_timeout
          http.write_timeout = write_timeout
        end
      end
    end

    # @param url [String] URL endpoint, such as '/app/ccv2r'
    # @param transaction [Minfraud::Transaction] transaction to be sent to MaxMind
    # @return [Minfraud::Response] wrapper for minFraud response
    def send_transaction(transaction:, url: DEFAULT_API)
      begin
        response = @http_client.get(url) do |req|
          req.params = self.class.encoded_query(transaction)
        end
        Response.new(response)
      rescue => e
        raise ConnectionException, "The minFraud connection failed due to #{e.class.name}"
      end
    end

    # Transforms Transaction object into a hash for request parameters
    # @param transaction [Transaction] transaction to be sent to MaxMind
    # @return [Hash] keys are strings with minFraud field names
    def self.encoded_query(transaction)
      Hash[transaction.attributes.map { |k, v| [FIELD_MAP[k], v] }]
    end

    private_constant(
      :DEFAULT_OPEN_TIMEOUT,
      :DEFAULT_IDLE_TIMEOUT,
      :DEFAULT_READ_TIMEOUT,
      :DEFAULT_WRITE_TIMEOUT,
      :DEFAULT_POOL_SIZE,
      :FIELD_MAP,
    )
  end
end
