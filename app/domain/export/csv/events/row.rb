# encoding: utf-8

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Csv::Events
  class Row < Export::Csv::Row

    self.dynamic_attributes = {
      /^contact_/  => :contactable_attribute,
      /^leader_/   => :contactable_attribute,
      /^date_\d+_/ => :date_attribute
    }

    def kind
      entry.kind.label
    end

    def state
      if entry.possible_states.present? && entry.state
        I18n.t("activerecord.attributes.event/course.states.#{entry.state}")
      else
        entry.state
      end
    end

    private

    def date_attribute(date_attr)
      _, index, attr = date_attr.to_s.split('_', 3)
      date = entry.dates[index.to_i]
      date.try(attr).try(:to_s)
    end

    # only the first leader is taken into account
    def leader
      leaders = entry.role_types.select(&:leader?)
      @leader ||= entry.participations_for(*leaders).first.try(:person)
    end

    def contact
      entry.contact
    end

    def contactable_attribute(contactable_attr)
      subject, attr = contactable_attr.to_s.split('_', 2)
      contactable = send(subject)
      if contactable
        contact_attr = :"contact_#{attr}"
        if respond_to?(contact_attr, true)
          send(contact_attr, contactable)
        else
          contactable.send(attr)
        end
      end
    end

    def contact_name(contactable)
      contactable.to_s
    end

    def contact_phone_numbers(contactable)
      contactable.phone_numbers.map(&:to_s).join(', ')
    end

  end
end
