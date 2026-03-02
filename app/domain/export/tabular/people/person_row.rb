#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::People
  class PersonRow < Export::Tabular::Row
    self.dynamic_attributes = {/^phone_number_/ => :phone_number_attribute,
                                /^social_account_/ => :social_account_attribute,
                                /^additional_email_/ => :additional_email_attribute,
                                /^additional_address_/ => :additional_address_attribute,
                                /^qualification_kind_/ => :qualification_kind}

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
      contact_account_attribute(filtered_accounts(entry.phone_numbers), attr)
    end

    def social_account_attribute(attr)
      contact_account_attribute(filtered_accounts(entry.social_accounts), attr)
    end

    def additional_email_attribute(attr)
      contact_account_attribute(filtered_accounts(entry.additional_emails), attr)
    end

    def additional_address_attribute(attr)
      contact_account_attribute(filtered_accounts(entry.additional_addresses), attr)
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

    def contact_account_attribute(accounts, attr)
      return custom_label_account_values(accounts) if custom_label?(accounts, attr)

      accounts.select do |e|
        ContactAccounts.key(e.class, e.label) == attr
      end.map(&:value).join(";").presence
    end

    def custom_label?(accounts, attr)
      return false if accounts.empty?

      ContactAccounts.custom_label_key(accounts.first.class) == attr
    end

    def custom_label_account_values(accounts)
      return if accounts.empty?

      model = accounts.first.class
      predefined = ContactAccounts.predefined_labels(model).map(&:downcase)
      accounts
        .reject { |e| predefined.include?(e.label&.downcase) }
        .map { |e| "#{e.label}:#{e.value}" }
        .join(";")
        .presence
    end
  end
end
