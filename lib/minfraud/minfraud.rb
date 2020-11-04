module Minfraud

  # Raised if a transaction is invalid
  class TransactionError < ArgumentError; end

  # Raised if minFraud returns an error
  class ResponseError < StandardError; end

  # Raised if there is an HTTP error on minFraud lookup
  class ConnectionException < StandardError; end

  DEFAULT_HOST = 'https://minfraud.maxmind.com'

  DEFAULT_API = '/app/ccv2r'

  SERVICE_HOSTS = {
    'us_east' => 'https://minfraud-us-east.maxmind.com',
    'us_west' => 'https://minfraud-us-west.maxmind.com',
    'eu_west' => 'https://minfraud-eu-west.maxmind.com',
  }

end
