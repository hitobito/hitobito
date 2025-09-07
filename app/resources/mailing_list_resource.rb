# frozen_string_literal: true

#  Copyright (c) 2025, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MailingListResource < ApplicationResource
  primary_endpoint "mailing_lists", [:index, :show]

  attribute :name, :string
  attribute :group_id, :integer
  attribute :description, :string
  attribute :publisher, :string
  attribute :mail_name, :string
  attribute :additional_sender, :string
  attribute :subscribable_for, :string
  attribute :subscribable_mode, :string
  attribute :subscribers_may_post, :boolean
  attribute :anyone_may_post, :boolean
  attribute :preferred_labels, :array
  attribute :delivery_report, :boolean
  attribute :main_email, :string
  attribute :subscribable, :boolean do
    @object.subscribable?
  end

  extra_attribute :subscribers, :array do
    MailingLists::Subscribers.new(@object, Person.only_public_data).people.map do |person|
      {
        primary_group_id: person.primary_group_id,
        primary_group_name: person.primary_group&.name,
        list_emails: Person.mailing_emails_for(person, @object.labels)
      }
    end
  end

  belongs_to :group, resource: GroupResource, writable: false

  def index_ability
    MailingListReadables.new(current_ability.user)
  end
end
