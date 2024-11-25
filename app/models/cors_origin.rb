# frozen_string_literal: true

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: cors_origins
#
#  id               :bigint           not null, primary key
#  auth_method_type :string
#  origin           :string           not null
#  auth_method_id   :bigint
#
# Indexes
#
#  index_cors_origins_on_auth_method_type_and_auth_method_id  (auth_method_type,auth_method_id)
#  index_cors_origins_on_origin                               (origin)
#

class CorsOrigin < ActiveRecord::Base
  belongs_to :auth_method, polymorphic: true

  validate :validate_cors_origin
  validates_by_schema

  def to_s
    origin
  end

  private

  def validate_cors_origin
    uri = ::URI.parse(origin)
    errors.add(:origin, :suffix_present) unless uri.fragment.nil?
    errors.add(:origin, :suffix_present) unless uri.query.nil?
    errors.add(:origin, :suffix_present) if uri.path.present?
    errors.add(:origin, :missing_hostname) if uri.host.nil?
    errors.add(:origin, :missing_scheme) if uri.opaque || uri.scheme.nil?
  rescue URI::InvalidURIError
    errors.add(:origin, :invalid_host)
  end
end
