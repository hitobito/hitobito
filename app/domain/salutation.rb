# frozen_string_literal: true

#  Copyright (c) 2021, Die Mitte. This file is part of
#  hitobito_die_mitte and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_die_mitte.

class Salutation

  I18N_KEY_PREFIX = 'activerecord.models.salutation'.freeze

  attr_reader :person

  class << self
    def all
      for_letters.merge(available).stringify_keys
    end

    def for_letters
      [[ :default,  I18n.t("#{I18N_KEY_PREFIX}.default.label") ]].tap do |values|
        next unless Settings.messages.personal_salutation
        values.append([:personal, I18n.t("#{I18N_KEY_PREFIX}.personal.label")])
      end.reverse.to_h
    end

    def available
      I18n.t("#{I18N_KEY_PREFIX}.available").each_with_object({}) do |s, h|
        h[s.first.to_s] = s.last[:label]
      end
    end
  end

  def initialize(person, salutation = nil)
    @person = person
    @salutation = salutation
  end

  def label
    I18n.translate("#{I18N_KEY_PREFIX}.#{salutation}.label")
  end

  def value
    gender = person.gender.presence || 'other'
    I18n.translate("#{I18N_KEY_PREFIX}.#{salutation}.value.#{gender}", attributes)
  end

  def attributes
    {
      first_name: person.first_name,
      last_name: person.last_name,
      greeting_name: person.greeting_name,
      company_name: person.company_name,
    }.tap do |attrs|
      next unless person.attributes.key?('title')

      attrs[:title] = person.title
      attrs[:title_last_name] = "#{person.title} #{person.last_name}".strip
    end
  end

  def salutation
    if self.class.available.keys.include?(@salutation)
      "available.#{@salutation}"
    elsif @salutation == 'personal' && @person.salutation?
      "available.#{@person.salutation}"
    else
      'default'
    end
  end
end
