# encoding: utf-8

#  Copyright (c) 2017-2021, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module SearchStrategies
  class Sql < Base

    MIN_TERM_LENGTH = 2

    SEARCH_FIELDS = {
      'Person' => {
        attrs: ['people.first_name', 'people.last_name', 'people.company_name', 'people.nickname',
                'people.company', 'people.email', 'people.address', 'people.zip_code',
                'people.town', 'people.country', 'people.birthday', 'people.additional_information',
                'phone_numbers.number', 'social_accounts.name', 'additional_emails.email'],
        joins: ['LEFT JOIN phone_numbers ON phone_numbers.contactable_id = people.id AND ' \
                "phone_numbers.contactable_type = 'Person'",
                'LEFT JOIN social_accounts ON social_accounts.contactable_id = people.id AND '\
                "phone_numbers.contactable_type = 'Person'",
                'LEFT JOIN additional_emails ON additional_emails.contactable_id = people.id AND '\
                "phone_numbers.contactable_type = 'Person'"]
      },
      'Group' => {
        attrs: ['groups.name', 'groups.short_name', 'groups.email',
                'groups.address', 'groups.zip_code', 'groups.town',
                'groups.country', 'parent.name', 'parent.short_name',
                'phone_numbers.number', 'social_accounts.name',
                'additional_emails.email'],

        joins: ["LEFT JOIN #{Group.quoted_table_name} parent ON " \
                "parent.id = #{Group.quoted_table_name}.parent_id",

                'LEFT JOIN phone_numbers ON ' \
                "phone_numbers.contactable_id = #{Group.quoted_table_name}.id AND " \
                "phone_numbers.contactable_type = 'Group'",

                'LEFT JOIN social_accounts ON ' \
                "social_accounts.contactable_id = #{Group.quoted_table_name}.id AND "\
                "phone_numbers.contactable_type = 'Group'",

                'LEFT JOIN additional_emails ON ' \
                "additional_emails.contactable_id = #{Group.quoted_table_name}.id AND "\
                "phone_numbers.contactable_type = 'Group'"]
      },
      'Event' => {
        attrs: ['event_translations.name', 'events.number', 'groups.name'],
        joins: ['LEFT JOIN event_translations ON event_translations.event_id = events.id',
                'INNER JOIN events_groups ON events.id = events_groups.event_id',
                "INNER JOIN #{Group.quoted_table_name} ON " \
                "events_groups.group_id = #{Group.quoted_table_name}.id"]
      },
      'Address' => {
        attrs: ['addresses.street_short', 'addresses.town', 'addresses.state',
                'addresses.zip_code', 'addresses.numbers']
      },
      'Invoice' => {
        attrs: ['invoices.title', 'invoices.reference',
                'invoices.sequence_number', 'groups.id'],
        joins: ["LEFT JOIN #{Group.quoted_table_name} ON " \
                "invoices.group_id = #{Group.quoted_table_name}.id"]
      }
    }.freeze

    def list_people
      return Person.none.page(1) unless term_present?

      Kaminari.paginate_array(super).page(@page)
    end

    def query_people
      return Person.none.page(1) unless term_present?

      query_accessible_people do |ids|
        query_entities(Person.where(id: ids)).page(1).per(QUERY_PER_PAGE)
      end
    end

    def query_groups
      return Group.none.page(1) unless term_present?

      query_entities(Group.all).page(1).per(QUERY_PER_PAGE)
    end

    def query_events
      return Event.none.page(1) unless term_present?

      query_entities(Event.includes(:groups, :dates).all).page(1).per(QUERY_PER_PAGE)
    end

    def query_addresses
      return Address.none.page(1) unless term_present?

      query_entities(Address.list).page(1).per(QUERY_PER_PAGE)
    end

    def query_invoices
      return Invoice.none.page(1) unless term_present?

      scope = Invoice.list.where(group_id: @user.finance_groups.pluck(:id))
      query_entities(scope).page(1).per(QUERY_PER_PAGE)
    end

    protected

    def fetch_people(ids)
      query_entities(Person.where(id: ids))
    end

    def query_entities(scope)
      fields = SEARCH_FIELDS[scope.model.sti_name]
      scope.joins(fields[:joins])
           .where(SqlConditionBuilder.new(@term, fields[:attrs]).search_conditions)
           .distinct
    end

    def term_present?
      @term.present? && @term.length > MIN_TERM_LENGTH
    end

  end
end
