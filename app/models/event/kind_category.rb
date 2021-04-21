# frozen_string_literal: true

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::KindCategory < ActiveRecord::Base

  include Paranoia::Globalized
  translates :label

  ### ASSOCIATIONS

  has_many :kinds, dependent: :nullify

  ### VALIDATIONS

  validates_by_schema
  # explicitly define validations for translated attributes
  validates :label, presence: true
  validates :label, length: { allow_nil: true, maximum: 255 }

  ### INSTANCE METHODS

  def to_s(_format = :default)
    label
  end

  # Soft destroy if events exist, otherwise hard destroy
  def destroy
    really_destroy!
  end

end
