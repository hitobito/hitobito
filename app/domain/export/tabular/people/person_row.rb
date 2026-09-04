#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::People
  class PersonRow < Export::Tabular::Row
    CONTACT_ACCOUNT_TYPES = [PhoneNumber, SocialAccount, AdditionalEmail, AdditionalAddress].freeze

    self.dynamic_attributes = {/^phone_number_/ => :phone_number_attribute,
                                /^social_account_/ => :social_account_attribute,
                                /^additional_email_/ => :additional_email_attribute,
                                /^additional_address_/ => :additional_address_attribute,
                                /^qualification_kind_/ => :qualification_kind}

    # Set by Export::Tabular::People::PeopleAddress#row_for to share one lookup
    # across all rows of an export; falls back to computing its own below if unset
    # (e.g. when a row is built directly, as in specs).
    attr_writer :contact_account_categories

    def country
      entry.country_label
    end

    def gender
      entry.gender_label
    end

    def roles
      if entry.try(:role_with_layer).present?
        entry.roles.zip(entry.role_with_layer.split(", ")).map { |arr| arr.join(" ") }.join(", ")
      else
        entry.roles.map { |role| "#{role} #{role.group.with_layer.join(" / ")}" }.join(", ")
      end
    end

    def tags
      entry.tag_list.to_s
    end

    def layer_group
      entry.layer_group.to_s
    end

    def address
      entry.address
    end

    private

    def phone_number_attribute(attr)
      contact_account_attribute(PhoneNumber, filtered_accounts(entry.phone_numbers), attr)
    end

    def social_account_attribute(attr)
      contact_account_attribute(SocialAccount, filtered_accounts(entry.social_accounts), attr)
    end

    def additional_email_attribute(attr)
      contact_account_attribute(AdditionalEmail, filtered_accounts(entry.additional_emails), attr)
    end

    def additional_address_attribute(attr)
      contact_account_attribute(AdditionalAddress, filtered_accounts(entry.additional_addresses),
        attr)
    end

    # PublicPersonRow overrides this method to only include public accounts
    def filtered_accounts(accounts)
      accounts
    end

    def qualification_kind(id)
      qualification = find_qualification(id)
      qualification.finish_at.try(:to_s) || I18n.t("global.yes") if qualification
    end

    def find_qualification(id)
      entry.decorate.latest_qualifications_uniq_by_kind.find do |q|
        qualification_active?(q) &&
          ContactAccounts.key(q.qualification_kind.class, q.qualification_kind.id.to_s) == id
      end
    end

    def qualification_active?(q)
      (q.start_at.blank? || q.start_at <= Time.zone.today) &&
        (q.finish_at.blank? || q.finish_at >= Time.zone.today)
    end

    def contact_account_attribute(model, accounts, attr)
      category = contact_account_categories.dig(model, attr)
      return unless category

      matches = accounts.select { |e| e.category_id == category.id }
      if category.other?
        return matches.map { |e|
          [e.label.presence, e.value].compact.join(":")
        }.join(";").presence
      end

      matches.map(&:value).join(";").presence
    end

    def contact_account_categories
      @contact_account_categories ||=
        ContactAccounts.categories_by_key(CONTACT_ACCOUNT_TYPES, Person.sti_name)
    end
  end
end
