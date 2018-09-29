module MailRelay
  class Recipient
    attr_reader :email_addresses
    def initialize(email_addresses)
      @email_adresses = email_addresses
    end

    def email_adresses
      @email_adresses
    end

  end
end
