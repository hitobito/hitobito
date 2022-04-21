# frozen_string_literal: true

#  Copyright (c) 2019-2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.


# == Schema Information
#
# Table name: oauth_applications
#
#  id           :integer          not null, primary key
#  confidential :boolean          default(TRUE), not null
#  name         :string(255)      not null
#  redirect_uri :text(16777215)   not null
#  scopes       :string(255)      default(""), not null
#  secret       :string(255)      not null
#  uid          :string(255)      not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_oauth_applications_on_uid  (uid) UNIQUE
#

module Oauth
  class Application < Doorkeeper::Application
    has_many :access_grants, dependent: :delete_all, class_name: 'Oauth::AccessGrant'
    has_many :access_tokens, dependent: :delete_all, class_name: 'Oauth::AccessToken'
    has_many :cors_origins, as: :auth_method, dependent: :delete_all
    accepts_nested_attributes_for :cors_origins, allow_destroy: true

    mount_uploader :carrierwave_logo, Oauth::LogoUploader, mount_on: 'logo'
    has_one_attached :logo, service: ENV['RAILS_ACTIVE_STORAGE_BACKEND'] do |attachable|
      attachable.variant :thumb, resize_to_fill: [64, 64]
    end
    if ENV['NOCHMAL_MIGRATION'].blank? # if not migrating RIGHT NOW, i.e. normal case
      validates :logo, dimension: { width: { max: 8_000 }, height: { max: 8_000 } },
                       content_type: ['image/jpeg', 'image/gif', 'image/png']
    end

    scope :list, -> { order(:name) }

    def self.human_scope(key)
      I18n.t("doorkeeper.scopes.#{key}")
    end

    def to_s
      name
    end

    def path_params(uri)
      { client_id: uid, redirect_uri: uri, response_type: 'code', scope: scopes }
    end

    def valid_access_tokens
      access_tokens.select do |access_token|
        !access_token.expired? && access_token.revoked_at.nil?
      end.count
    end

    def valid_access_grants
      access_grants.select do |access_grant|
        !access_grant.expired? && access_grant.revoked_at.nil?
      end.count
    end

    def remove_logo
      false
    end

    def remove_logo=(delete_it)
      logo.purge_later if delete_it
    end

  end
end
