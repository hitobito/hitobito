module MailRelay
  # A generic email relay object. Retrieves messages from a mail server and resends them to a list of recievers.
  # In subclasses, override the methods #relay_address?, #sender_allowed? and #receivers 
  # to constrain which mails are sent to whom.
  class Base
    
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
    
    # Heuristic method to find actual receiver of the message.
    # May return nil if could not determine.
    def envelope_receiver
      if received = message.received && message.received.first
        received.info[/ for .*?([^\s<>]+@[^\s<>]+)/, 1]
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