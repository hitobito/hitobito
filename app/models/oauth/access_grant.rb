# frozen_string_literal: true

# Copyright (c) 2021, CVP Schweiz. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: oauth_access_grants
#
#  id                    :integer          not null, primary key
#  code_challenge        :string(255)
#  code_challenge_method :string(255)
#  expires_in            :integer          not null
#  redirect_uri          :text(65535)      not null
#  revoked_at            :datetime
#  scopes                :string(255)
#  token                 :string(255)      not null
#  created_at            :datetime         not null
#  application_id        :integer          not null
#  resource_owner_id     :integer          not null
#
# Indexes
#
#  fk_rails_b4b53e07b8                 (application_id)
#  index_oauth_access_grants_on_token  (token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (application_id => oauth_applications.id)
#

module Oauth
  class AccessGrant < Doorkeeper::AccessGrant
    belongs_to :person, foreign_key: :resource_owner_id, inverse_of: :access_grants

    scope :list, -> { order(created_at: :desc) }
    scope :for, ->(uri) { where(redirect_uri: uri) }
    scope :not_expired, -> { where("DATE_ADD(created_at, INTERVAL expires_in SECOND) > UTC_TIME") }

    def self.active
      if connection.adapter_name == "Mysql2"
        not_expired.where(revoked_at: nil)
      else
        where(revoked_at: nil)
      end
    end

    def to_s
      token
    end
  end
end
