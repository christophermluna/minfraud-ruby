module Minfraud

  # This class wraps the raw minFraud response. Any minFraud response field is accessible on a Response
  # instance as a snake-cased instance method. For example, if you want the `ip_corporateProxy`
  # field from minFraud, you can get it with `#ip_corporate_proxy`.
  class Response

    ERROR_CODES = %w( INVALID_LICENSE_KEY IP_REQUIRED LICENSE_REQUIRED COUNTRY_REQUIRED MAX_REQUESTS_REACHED )
    WARNING_CODES = %w( IP_NOT_FOUND COUNTRY_NOT_FOUND CITY_NOT_FOUND CITY_REQUIRED POSTAL_CODE_REQUIRED POSTAL_CODE_NOT_FOUND )
    INTEGER_ATTRIBUTES = %i(distance queries_remaining ip_accuracy_radius ip_metro_code)
    FLOAT_ATTRIBUTES = %i(ip_latitude ip_longitude score risk_score proxy_score ip_country_conf ip_region_conf ip_city_conf ip_postal_conf)
    BOOLEAN_ATTRIBUTES = %i(country_match high_risk_country anonymous_proxy ip_corporate_proxy free_mail carder_email prepaid city_postal_match
                            ship_city_postal_match bin_match bin_name_match bin_phone_match cust_phone_in_billing_loc ship_forward)
    BOOLEAN_RESPONSES = {
      "Yes"      => true,
      "No"       => false,
      "NA"       => nil,
      "NotFound" => nil,
    }

    # Sets attributes on self using minFraud response keys and values
    # Raises an exception if minFraud returns an error message
    # Does nothing (at the moment) if minFraud returns a warning message
    # Raises an exception if minFraud responds with anything other than an HTTP success code
    # @param raw [Net::HTTPResponse]
    def initialize(raw)
      @raw = raw
    end

    def parse
      @body ||= decode_body
    end

    def code
      @raw.code
    end

    private

    # Parses raw response body and turns its keys and values into attributes on self.
    # @param body [String] raw response body string
    def decode_body
      raise ConnectionException, "The minFraud service responded with http error #{@raw.class}" unless @raw.is_a?(Net::HTTPSuccess)
      transform_keys(Hash[(@raw.body.force_encoding("ISO-8859-1").split(';').reject! { |e| e.empty? }).map { |e| e.split('=', 2) }]).tap do |body|
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
          key = key.
          gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').
          gsub(/([a-z])([A-Z])/, '\1_\2').
          downcase.
          to_sym
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
