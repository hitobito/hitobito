module MailRelay
  class Recipient

    attr_reader :email_addresses

    def initialize(email_addresses)
      @email_addresses = email_addresses
    end


    def email_addresses
      @email_addresses
    end


    def equal?(other)
      return false if other.nil?
      return false if other.kind_of? Array
      return false unless other.kind_of? Recipient
      @email_addresses == other.email_addresses
    end

    def ==(other)
      equal? other
    end


  end
end
