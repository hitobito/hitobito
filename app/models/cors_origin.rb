# frozen_string_literal: true

# == Schema Information
#
# Table name: cors_origins
#
#  id               :bigint           not null, primary key
#  auth_method_type :string(255)
#  auth_method_id   :bigint
#  origin           :string(255)      not null
#
#  Copyright (c) 2021, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

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
