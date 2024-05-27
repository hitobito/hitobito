# frozen_string_literal: true

#  Copyright (c) 2014-2024, CEVI Regionalverband ZH-SH-GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: people
#
#  id                                   :integer          not null, primary key
#  additional_information               :text(65535)
#  address                              :text(65535)
#  authentication_token                 :string(255)
#  birthday                             :date
#  blocked_at                           :datetime
#  company                              :boolean          default(FALSE), not null
#  company_name                         :string(255)
#  confirmation_sent_at                 :datetime
#  confirmation_token                   :string(255)
#  confirmed_at                         :datetime
#  contact_data_visible                 :boolean          default(FALSE), not null
#  country                              :string(255)
#  current_sign_in_at                   :datetime
#  current_sign_in_ip                   :string(255)
#  email                                :string(255)
#  encrypted_password                   :string(255)
#  encrypted_two_fa_secret              :text(65535)
#  event_feed_token                     :string(255)
#  failed_attempts                      :integer          default(0)
#  family_key                           :string(255)
#  first_name                           :string(255)
#  gender                               :string(1)
#  household_key                        :string(255)
#  inactivity_block_warning_sent_at     :datetime
#  language                             :string(255)      default("de"), not null
#  last_name                            :string(255)
#  last_sign_in_at                      :datetime
#  last_sign_in_ip                      :string(255)
#  locked_at                            :datetime
#  minimized_at                         :datetime
#  nickname                             :string(255)
#  privacy_policy_accepted_at           :datetime
#  remember_created_at                  :datetime
#  reset_password_sent_at               :datetime
#  reset_password_sent_to               :string(255)
#  reset_password_token                 :string(255)
#  self_registration_reason_custom_text :string(100)
#  show_global_label_formats            :boolean          default(TRUE), not null
#  sign_in_count                        :integer          default(0)
#  town                                 :string(255)
#  two_factor_authentication            :integer
#  unconfirmed_email                    :string(255)
#  unlock_token                         :string(255)
#  zip_code                             :string(255)
#  created_at                           :datetime
#  updated_at                           :datetime
#  creator_id                           :integer
#  last_label_format_id                 :integer
#  primary_group_id                     :integer
#  self_registration_reason_id          :bigint
#  updater_id                           :integer
#
# Indexes
#
#  index_people_on_authentication_token         (authentication_token)
#  index_people_on_confirmation_token           (confirmation_token) UNIQUE
#  index_people_on_email                        (email) UNIQUE
#  index_people_on_event_feed_token             (event_feed_token) UNIQUE
#  index_people_on_first_name                   (first_name)
#  index_people_on_household_key                (household_key)
#  index_people_on_last_name                    (last_name)
#  index_people_on_reset_password_token         (reset_password_token) UNIQUE
#  index_people_on_self_registration_reason_id  (self_registration_reason_id)
#  index_people_on_unlock_token                 (unlock_token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (self_registration_reason_id => self_registration_reasons.id)
#

# Serializes a single person. Expects the following context arguments:
#  * group - The group this person is showed for
class PersonSerializer < ApplicationSerializer
  include ContactableSerializer

  schema do # rubocop:disable Metrics/BlockLength
    details = h.can?(:show_details, item)
    full = h.can?(:show_full, item)

    json_api_properties

    property :href, h.group_person_url(context[:group], item, format: :json)

    map_properties :first_name,
                   :last_name,
                   :nickname,
                   :company_name,
                   :company,
                   :email

    property :address, item.address # computed, not a real attribute

    map_properties :zip_code,
                   :town,
                   :country,
                   :household_key

    property :picture, item.picture_full_url
    property :tags, item.tag_list if h.can?(:index_tags, item)

    apply_extensions(:public)

    contact_accounts(!details)

    if details
      map_properties :birthday,
                     :gender,
                     :additional_information


      apply_extensions(:details, show_full: full)

      modification_properties
    end

    entity :primary_group, item.primary_group, GroupLinkSerializer
    group_template_link 'people.primary_group'

    entities :roles, item.filtered_roles(full ? nil : context[:group]), RoleSerializer
  end
end
