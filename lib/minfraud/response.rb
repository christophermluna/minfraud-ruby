module Minfraud

  # This class wraps the raw minFraud response. Any minFraud response field is accessible on a Response
  # instance as a snake-cased instance method. For example, if you want the `ip_corporateProxy`
  # field from minFraud, you can get it with `#ip_corporate_proxy`.
  # After initialization, the Response object will be immutable
  class Response

    # Allow the parsed response body to be accessed as a Hash
    attr_reader :body

    ERROR_CODES = %w(
      INVALID_LICENSE_KEY IP_REQUIRED MAX_REQUESTS_REACHED LICENSE_REQUIRED PERMISSION_REQUIRED
    ).freeze

    # The client does not handle warnings
    # If a warning is present, it will be found in the :err attribute of the Response
    WARNING_CODES = %w(
      IP_NOT_FOUND COUNTRY_NOT_FOUND CITY_NOT_FOUND CITY_REQUIRED
      INVALID_EMAIL_MD5 POSTAL_CODE_REQUIRED POSTAL_CODE_NOT_FOUND
    ).freeze

    INTEGER_ATTRIBUTES = %i(
      distance queries_remaining ip_accuracy_radius ip_metro_code
    ).freeze

    FLOAT_ATTRIBUTES = %i(
      ip_latitude ip_longitude score risk_score proxy_score ip_country_conf
      ip_region_conf ip_city_conf ip_postal_conf
    ).freeze

    BOOLEAN_ATTRIBUTES = %i(
      country_match high_risk_country anonymous_proxy ip_corporate_proxy free_mail
      carder_email prepaid city_postal_match ship_city_postal_match bin_match
      bin_name_match bin_phone_match cust_phone_in_billing_loc ship_forward
    ).freeze

    BOOLEAN_RESPONSES = {
      "Yes"      => true,
      "No"       => false,
      "NA"       => nil,
      "NotFound" => nil,
    }.freeze

    # Initializes the Response with the data retrieved from the MinfraudClient
    # If successful, keys and values from the response will be turned into attributes on self
    # After initialization, the Response object will be immutable
    # @raise [ConnectionException, ResponseError] if response was not successful
    # @param raw [Faraday::Response] the response data from MinfraudClient
    # @yield [Minfraud::Response] to allow modification of fields in the response
    def initialize(raw, &block)
      @body = decode_body(raw)
      if block_given?
        # Allow for any changes to the response body before freezing the object
        block.call(@body)
      end
      freeze
      @body.freeze
    end

    private

    # Parses raw response body and turns its keys and values into attributes on self.
    # @raise [ConnectionException, ResponseError] if response was not successful
    def decode_body(raw)
      unless raw.success?
        raise ConnectionException, "The minFraud service responded with http error #{raw.status.to_s}"
      end

      parsed_body = raw.body.force_encoding("ISO-8859-1").split(';').reject { |e| e.empty? }
      parsed_keys = Hash[(parsed_body).map { |e| e.split('=', 2) }]

      transform_keys(parsed_keys).tap do |body|
        raise ResponseError, "Error message from minFraud: #{body[:err]}" if ERROR_CODES.include?(body[:err])
      end
    end

    # Snake cases and symbolizes keys in passed hash.
    # Transforms values to boolean, integer and float types when applicable
    # @param hash [Hash]
    def transform_keys(hash)
      hash = hash.to_a
      hash.map! do |e|
        key = e.first
        if key.match(/\A[A-Z]+\z/)
          key = key.downcase
        else
          key = key.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
                   .gsub(/([a-z])([A-Z])/, '\1_\2')
                   .downcase
                   .to_sym
        end

        value = e.last
        value = if BOOLEAN_ATTRIBUTES.include?(key)
          BOOLEAN_RESPONSES[value]
        elsif INTEGER_ATTRIBUTES.include?(key)
          value.to_i
        elsif FLOAT_ATTRIBUTES.include?(key)
          value.to_f
        elsif value
          value.encode(Encoding::UTF_8)
        end

        [key, value]
      end
      Hash[hash]
    end

    # Allows keys in hash contained in @body to be used as methods
    def method_missing(meth, *args, &block)
      # We're not calling super because we want nil if an attribute isn't found
      @body[meth]
    end

  end
end
