require 'digest/md5'

module Minfraud

  # This is the container for the data you're sending to MaxMind.
  # A transaction holds data like name, address, IP, order amount, etc.
  # After initialization, the Transaction object will be immutable
  class Transaction

    # Required attribute
    attr_accessor :ip, :txn_id, :license_key

    # Billing address (optional)
    attr_accessor :city, :state, :postal, :country

    # Shipping address attribute (optional)
    attr_accessor :ship_addr, :ship_city, :ship_state, :ship_postal, :ship_country

    # User attribute (optional)
    attr_accessor :email, :phone

    # Credit card attribute (optional)
    attr_accessor :bin

    # Transaction linking attribute (optional)
    attr_accessor :user_agent, :accept_language

    # Transaction attribute (optional)
    attr_accessor :amount, :currency, :txn_type, :shop_id

    # Credit card result attribute (optional)
    attr_accessor :avs_result, :cvv_result

    # Miscellaneous attribute (optional)
    attr_accessor :requested_type

    ATTRIBUTES = [
      :ip, :txn_id, :license_key,
      :city, :state, :postal, :country,
      :ship_addr, :ship_city, :ship_state, :ship_postal, :ship_country,
      :email_domain, :email_md5, :phone,
      :bin,
      :user_agent, :accept_language,
      :amount, :currency, :txn_type, :shop_id,
      :avs_result, :cvv_result,
      :requested_type
    ].freeze

    INPUT_STRING_ATTRIBUTES = [
      :ip, :txn_id, :license_key,
      :city, :state, :postal, :country,
      :ship_addr, :ship_city, :ship_state, :ship_postal, :ship_country,
      :email, :phone,
      :bin,
      :user_agent, :accept_language,
      :currency, :txn_type,
      :avs_result, :cvv_result,
      :requested_type
    ].freeze

    INPUT_NUMERIC_ATTRIBUTES = [:amount].freeze

    REQUIRED_ATTRIBUTES = [:ip, :txn_id, :license_key].freeze

    CONVERT_STRING_ATTRIBUTES = [:shop_id].freeze

    # Initializes the Transaction using parameters set from the block
    # @raise [TransactionAttributeValidationError] if parameters are set incorrectly
    # @raise [TransactionAttributesMissingError] if required parameters are missing
    def initialize(strong_validation: true)
      Rails.logger.info("This is a test of warning logs")
      yield self
      unless has_required_attributes?
        raise TransactionAttributesMissingError, 'You did not set all the required transaction attributes.'
      end
      validate_attributes if strong_validation
      freeze
    end

    # Hash of attributes that have been set
    # @return [Hash] present attributes
    def attributes
      Hash[ATTRIBUTES.map { |a| [a, send(a)] }].compact
    end

    private

    # Ensures the required attributes are present
    # @return [Boolean]
    def has_required_attributes?
      REQUIRED_ATTRIBUTES.none? { |attr| send(attr).nil? || send(attr).empty? }
    end

    # Validates the types of the attributes
    # @raise [TransactionAttributeValidationError] if present attributes are not valid
    # @return [void]
    def validate_attributes
      Rails.logger.info("T his is a warning log")
      INPUT_STRING_ATTRIBUTES.each { |attr| validate_string(attr) }
      INPUT_NUMERIC_ATTRIBUTES.each { |attr| validate_number(attr) }
      CONVERT_STRING_ATTRIBUTES.each { |attr| convert_to_string(attr) }
      validate_cvv # CVV must be a single character
    end

    # Given the symbol of an attribute that should be a string,
    # it checks the attribute's type and throws an error if it's not a string.
    # @param attr_name [Symbol] name of the attribute to validate
    # @raise [TransactionAttributeValidationError] if attribute is not a string
    # @return [void]
    def validate_string(attr_name)
      attribute = send(attr_name)
      if attribute && !attribute.instance_of?(String)
        raise TransactionAttributeValidationError, "Transaction.#{attr_name} must be a string"
      end
    end

    # Given the symbol of an attribute that should be a number,
    # it checks the attribute's type and throws an error if it
    # cannot be interpreted as a BigDecimal
    # @param attr_name [Symbol] name of the attribute to validate
    # @raise [TransactionAttributeValidationError] if attribute is not a number
    # @return [void]
    def validate_number(attr_name)
      attribute = send(attr_name)
      return if attribute.nil? || attribute.is_a?(Numeric)
      begin
        BigDecimal(attribute)
      rescue
        raise TransactionAttributeValidationError, "Transaction.#{attr_name} must be a number"
      end
    end

    # Validates the cvv_result, which must be a single character
    # @raise [TransactionAttributeValidationError] if cvv_result is not a single character
    # @return [void]
    def validate_cvv
      return if cvv_result.nil? || cvv_result.empty?
      unless cvv_result.length == 1
        raise TransactionAttributeValidationError, "Transaction.cvv_result must be a single letter"
      end
    end

    # Converts the given attribute to a string
    # @param attr_name [Symbol] name of the attribute to convert
    # @return [void]
    def convert_to_string(attr_name)
      attribute = send(attr_name)
      return if attribute.nil?
      send("#{attr_name}=", attribute.to_s)
    end

    # @return [String, nil] domain of the email address
    def email_domain
      return nil if email.nil? || email.empty?
      email.to_s.split('@').last
    end

    # @return [String, nil] MD5 hash of the whole email address
    def email_md5
      return nil if email.nil? || email.empty?
      # convert the email address to lowercase before calculating its MD5 hash
      Digest::MD5.hexdigest(email.to_s.downcase).to_s
    end

    private_constant(
      :ATTRIBUTES,
      :INPUT_STRING_ATTRIBUTES,
      :INPUT_NUMERIC_ATTRIBUTES,
      :REQUIRED_ATTRIBUTES
    )

  end
end
