# encoding: utf-8

#  Copyright (c) 2012-2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module MailRelay
  class AddressList

    attr_reader :people, :labels

    def initialize(people, labels = [])
      @people = Array(people)
      @labels = labels
    end

    def entries
      people.flat_map do |person|
        preferred_emails(person).presence || default_emails(person)
      end.reject(&:blank?).uniq
    end

    private

    def preferred_emails(person)
      additional_emails_with_default(person).select do |email|
        sanitized_labels.include?(email.label.strip.downcase)
      end.collect(&:email)
    end

    def default_emails(person)
      [person.email] + additional_emails(person).select(&:mailings?).collect(&:email)
    end

    def sanitized_labels
      @sanitized_labels ||= labels.collect do |label|
        label.strip.downcase
      end.compact
    end

    def additional_emails_with_default(person)
      additional_emails(person) + [default_additional_email(person)]
    end

    def default_additional_email(person)
      AdditionalEmail.new(label: MailingList::DEFAULT_LABEL, email: person.email)
    end

    def additional_emails(person)
      @additional_emails ||= additional_emails_scope.
        each_with_object(hash_with_array) do |email, memo|
          memo[email.contactable_id] << email
      end
      @additional_emails[person.id]
    end

    def hash_with_array
      Hash.new { |h, k| h[k] = [] }
    end

    def additional_emails_scope
      AdditionalEmail.where(contactable_type: Person.sti_name,
                            contactable_id: people.collect(&:id))
    end

  end
end
