module MailRelay
  class AddressList

    attr_reader :people, :preferred_labels

    def initialize(people, preferred_labels = [])
      @people = Array(people)
      @preferred_labels = []
    end

    def entries
      sanitized(emails + additional_emails)
    end

    def sanitized(list)
      list.select(&:present?).uniq
    end

    def emails
      people.collect(&:email)
    end

    def additional_emails
      AdditionalEmail.mailing_emails_for(people)
    end

  end
end
