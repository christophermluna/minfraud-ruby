# Ruby interface to the MaxMind minFraud API

Compatible with [minFraud](http://www.maxmind.com/en/ccv_overview) Legacy API

[minFraud API documentation](https://dev.maxmind.com/minfraud/minfraud-legacy/)  

## Usage

```ruby
minfraud_client = Minfraud::MinfraudClient.new(
  # Optional fields to customize connection
  host_choice: 'us_east',
  open_timeout: 1,
  idle_timeout: 5,
  read_timeout: 5,
  write_timeout: 5,
  pool_size: 10
)

transaction = Minfraud::Transaction.new do |t|
  # Required fields
  # Other fields listed later in documentation are optional
  t.ip = '1.2.3.4'
  t.city = 'richmond'
  t.state = 'virginia'
  t.postal = '12345'
  t.country = 'US' # http://en.wikipedia.org/wiki/ISO_3166-1
  t.txn_id = 'Order-1'
  t.license_key = 'minfraud-license-key'
  # ...
end

response = minfraud_client.send_transaction(
  transaction: transaction,
  # Optional field to customize connection
  url: '/app/ccv2r'
)

response.parse # parses body to create hash

response.dig(:risk_score)
# => 3.48
```

### Exception handling

There are three different exceptions that this gem may raise. Please be prepared to handle them:

```ruby
# Raised if a transaction is invalid
class TransactionError < ArgumentError; end

# Raised if minFraud returns an error
class ResponseError < StandardError; end

# Raised if there is an HTTP error on minFraud lookup
class ConnectionException < StandardError; end
```

### Transaction fields

#### Required

| name          | type (length)         | example                             | description |
| ------------- | --------------------- | ----------------------------------- | ----------- |
| ip            | string                | `t.ip = '1.2.3.4'`                  | Customer IP address |
| city          | string                | `t.city = 'new york'`               | Customer city |
| state         | string                | `t.state = 'new york'`              | Customer state/province/region |
| postal        | string                | `t.postal = '10014'`                | Customer zip/postal code |
| country       | string                | `t.country = 'US'`                  | Customer ISO 3166-1 country code |
| txn_id        | string                | `t.txn_id = 'Order-1'`              | Transaction/order id

#### Optional

| name               | type (length)      | description |
| ------------------ | ------------------ | ----------- |
| ship_addr          | string             | |
| ship_city          | string             | |
| ship_state         | string             | |
| ship_postal        | string             | |
| ship_country       | string             | |
| email              | string             | We will hash the email for you |
| phone              | string             | Any format acceptable |
| bin                | string             | CC bin number (first 6 digits) |
| session_id         | string             | Used for linking transactions |
| user_agent         | string             | Used for linking transactions |
| accept_language    | string             | Used for linking transactions |
| amount             | string             | Transaction amount |
| currency           | string             | ISO 4217 currency code |
| txn_type           | string             | creditcard/debitcard/paypal/google/other/lead/survey/sitereg |
| avs_result         | string             | Standard AVS response code |
| cvv_result         | string             | Y/N |
| requested_type     | string             | standard/premium |
| forwarded_ip       | string             | The end user’s IP address, as forwarded by a transparent proxy |
