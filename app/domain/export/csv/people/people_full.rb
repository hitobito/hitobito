# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Csv::People
  # adds social_accounts and company related attributes
  class PeopleFull < PeopleAddress

    EXCLUDED_ATTRS = %w(id
                        contact_data_visible
                        created_at
                        creator_id
                        updated_at
                        updater_id
                        encrypted_password
                        reset_password_token
                        reset_password_sent_at
                        remember_created_at
                        sign_in_count
                        current_sign_in_at
                        last_sign_in_at
                        current_sign_in_ip
                        last_sign_in_ip
                        failed_attempts
                        locked_at
                        picture
                        primary_group_id
                        last_label_format_id)

    def person_attributes
      (model_class.column_names - EXCLUDED_ATTRS).collect(&:to_sym) + [:roles]
    end

    def association_attributes
      account_labels(people.map(&:additional_emails).flatten, AdditionalEmail).merge(
        account_labels(people.map(&:phone_numbers).flatten, PhoneNumber).merge(
          account_labels(people.map(&:social_accounts).flatten, SocialAccount)))
    end
  end
end
