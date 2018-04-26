# encoding: utf-8
# == Schema Information
#
# Table name: people
#
#  id                        :integer          not null, primary key
#  first_name                :string(255)
#  last_name                 :string(255)
#  company_name              :string(255)
#  nickname                  :string(255)
#  company                   :boolean          default(FALSE), not null
#  email                     :string(255)
#  address                   :string(1024)
#  zip_code                  :string(255)
#  town                      :string(255)
#  country                   :string(255)
#  gender                    :string(1)
#  birthday                  :date
#  additional_information    :text(65535)
#  contact_data_visible      :boolean          default(FALSE), not null
#  created_at                :datetime
#  updated_at                :datetime
#  encrypted_password        :string(255)
#  reset_password_token      :string(255)
#  reset_password_sent_at    :datetime
#  remember_created_at       :datetime
#  sign_in_count             :integer          default(0)
#  current_sign_in_at        :datetime
#  last_sign_in_at           :datetime
#  current_sign_in_ip        :string(255)
#  last_sign_in_ip           :string(255)
#  picture                   :string(255)
#  last_label_format_id      :integer
#  creator_id                :integer
#  updater_id                :integer
#  primary_group_id          :integer
#  failed_attempts           :integer          default(0)
#  locked_at                 :datetime
#  authentication_token      :string(255)
#  show_global_label_formats :boolean          default(TRUE), not null
#  household_key             :string(255)
#

#  Copyright (c) 2014, CEVI Regionalverband ZH-SH-GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Serializes a single person. Expects the following context arguments:
#  * group - The group this person is showed for
class PersonSerializer < ApplicationSerializer
  include ContactableSerializer

  schema do
    details = h.can?(:show_details, item)
    full = h.can?(:show_full, item)

    json_api_properties

    property :href, h.group_person_url(context[:group], item, format: :json)

    map_properties :first_name,
                   :last_name,
                   :nickname,
                   :company_name,
                   :company,
                   :email,
                   :address,
                   :zip_code,
                   :town,
                   :country

    property :picture, item.picture_full_url
    property :tags, item.tag_list.to_s if h.can?(:index_tags, item)

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
