module MailRelay
  # A generic email relay object. Retrieves messages from a mail server and resends them to a list of recievers.
  # In subclasses, override the methods #relay_address?, #sender_allowed? and #receivers 
  # to constrain which mails are sent to whom.
  class Base
    
    # Define a header that contains the original receiver address.
    # This header could be set by the mail server.
    cattr :receiver_header
    self.receiver_header = 'X-Envelope-To'
    
    attr_reader :message
    
    # Retrieve, process and delete all mails from the mail server.
    def self.relay_current
      begin
        messages = Mail.find_and_delete
        messages.each do |message|
          self.new(message).relay
        end
      end while messages.present?
    end
    
    def initialize(message)
      @message = message
    end
    
    # Process the given email.
    def relay
      if relay_address?
        if sender_allowed?
          resend
        else
          reject_not_allowed
        end
      else
        reject_not_existing
      end
    end
    
    # Send the same mail to all receivers, if any.
    def resend
      destinations = receivers
      if destinations.present?
        message.singleton_class.send(:include, ManualDestinations)
        message.destinations = destinations
        if defined?(ActionMailer::Base)
          ActionMailer::Base.wrap_delivery_behavior(message)
        end
        message.deliver
      end
    end
    
    # If the email sender was not allowed to post messages, this method is called.
    # Silently ignores the message by default.
    def reject_not_allowed
      # do nothing
    end
    
    # If the email is sent to an address that is not a valid relay, this method is called.
    # Silently ignores the message by default.
    def reject_not_existing
      # do nothing
    end
    
    # 
    def original_receiver
      receiver_from_x_header || 
      receiver_from_received_header || 
      raise("Could not determine original receiver for email:\n#{message.header}")
    end
    
    # Heuristic method to find actual receiver of the message.
    # May return nil if could not determine.
    def receiver_from_received_header
      if received = message.received
        received = received.first if received.respond_to?(:first)
        received.info[/ for .*?([^\s<>]+@[^\s<>]+)/, 1]
      end
    end
    
    def receiver_from_x_header
      if field = message.header[receiver_header]
        field.to_s.split('@', 2).first
      end
    end
    
    # Is the mail sent to a valid relay address?
    def relay_address?
      true
    end
    
    # Is the mail sender allowed to post to this address
    def sender_allowed?
      true
    end
    
    # List of receiver email addresses for the resent email.
    def receivers
      []
    end
    
  end
end