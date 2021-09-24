# frozen_string_literal: true

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::KindCategory < ActiveRecord::Base

  include Globalized
  translates :label

  ### ASSOCIATIONS

  has_many :kinds, dependent: :nullify

  ### VALIDATIONS

  validates_by_schema
  # explicitly define validations for translated attributes
  validates :label, presence: true
  validates :label, length: { allow_nil: true, maximum: 255 }
  validates :order, numericality: { only_integer: true }

  ### INSTANCE METHODS

  ### SCOPES
  default_scope -> { order('`order`') }

  def to_s(_format = :default)
    label
  end

end
