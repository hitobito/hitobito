# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Agnostic::People::Row
  # Attributes of a person, handles associations


  def country
    entry.country_label
  end

  def gender
    entry.gender_label
  end

  def roles
    entry.roles.map { |role| "#{role} #{role.group.with_layer.join(' / ')}" }.join(', ')
  end

  def tags
    entry.tag_list.to_s
  end

  private

  def phone_number_attribute(attr)
    contact_account_attribute(entry.phone_numbers, attr)
  end

  def social_account_attribute(attr)
    contact_account_attribute(entry.social_accounts, attr)
  end

  def additional_email_attribute(attr)
    contact_account_attribute(entry.additional_emails, attr)
  end

  def people_relation_attribute(attr)
    entry.relations_to_tails.
      select { |r| :"people_relation_#{r.kind}" == attr }.
      map { |r| r.tail.to_s }.
      join(', ')
  end

  def qualification_kind(attr)
    qualification = entry.qualifications
                      .flatten
                      .reject { |q| !q.start_at.blank? && q.start_at > Time.zone.today }
                      .reject { |q| !q.finish_at.blank? && q.finish_at < Time.zone.today }
                      .find { |e|
      Export::Agnostic::People::ContactAccounts.key(e.qualification_kind.class,
                                                    e.qualification_kind.label) == attr
    }
    qualification.finish_at.try(:to_s) || I18n.t('global.yes') if qualification
  end

  def contact_account_attribute(accounts, attr)
    account = accounts.find { |e|
      Export::Agnostic::People::ContactAccounts.key(e.class, e.translated_label) == attr
    }
    account.value if account
  end

end

