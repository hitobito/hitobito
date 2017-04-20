# encoding: utf-8

#  Copyright (c) 2017, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module SearchStrategies
  class Sql < Base

    MIN_TERM_LENGTH = 2

    SEARCH_FIELDS = {
      'Person' => {
        attrs: [:first_name, :last_name, :company_name, :nickname, :company, 'people.email',
                :address, :zip_code, :town, :country, :birthday, :additional_information,
                'phone_numbers.number', 'social_accounts.name', 'additional_emails.email'],
        joins: ['LEFT JOIN phone_numbers ON phone_numbers.contactable_id = people.id AND ' \
                'phone_numbers.contactable_type = \'Person\'',
                'LEFT JOIN social_accounts ON social_accounts.contactable_id = people.id AND '\
                'phone_numbers.contactable_type = \'Person\'',
                'LEFT JOIN additional_emails ON additional_emails.contactable_id = people.id AND '\
                'phone_numbers.contactable_type = \'Person\'']
      },
      'Group' => {
        attrs: ['groups.name', 'groups.short_name', 'groups.email', 'groups.address',
                'groups.zip_code', 'groups.town', 'groups.country',
                'parent.name', 'parent.short_name', 'phone_numbers.number', 'social_accounts.name',
                'additional_emails.email'],
        joins: ['LEFT JOIN groups parent ON parent.id = groups.parent_id',
                'LEFT JOIN phone_numbers ON phone_numbers.contactable_id = groups.id AND ' \
                'phone_numbers.contactable_type = \'Group\'',
                'LEFT JOIN social_accounts ON social_accounts.contactable_id = groups.id AND '\
                'phone_numbers.contactable_type = \'Group\'',
                'LEFT JOIN additional_emails ON additional_emails.contactable_id = groups.id AND '\
                'phone_numbers.contactable_type = \'Group\'']
      },
      'Event' => {
        attrs: ['events.name', :number, 'groups.name'],
        joins: [:groups]
      }
    }.freeze

    def list_people
      return Person.none.page(1) unless term_present?
      Kaminari.paginate_array(super).page(@page)
    end

    def query_people
      return Person.none.page(1) unless term_present?
      query_accessible_people do |ids|
        query_entities(Person.where(id: ids)).page(1).per(10)
      end
    end

    def query_groups
      return Group.none.page(1) unless term_present?
      query_entities(Group.all).page(1).per(10)
    end

    def query_events
      return Event.none.page(1) unless term_present?
      query_entities(Event.all).page(1).per(10)
    end

    protected

    def fetch_people(ids)
      query_entities(Person.where(id: ids))
    end

    def query_entities(scope)
      fields = SEARCH_FIELDS[scope.model.sti_name]
      scope.joins(fields[:joins])
           .where(sql_search_condition(fields[:attrs]))
    end

    def sql_search_condition(attrs)
      [attrs.map { |attr| "#{attr} LIKE ?" }.join(' OR ')] + attrs.map { "%#{@term}%" }
    end

    def term_present?
      @term.present? && @term.length > MIN_TERM_LENGTH
    end

  end
end
