# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
class Assignment < ActiveRecord::Base
  ATTACHMENT_TYPES = [Message::Letter, Message::LetterWithInvoice].freeze
  include I18nEnums

  belongs_to :person
  belongs_to :creator, class_name: "Person"
  belongs_to :attachment, polymorphic: true

  after_create :attachment_prepare_print

  scope :list, -> { order(:created_at) }

  attr_readonly :person_id
  attr_readonly :creator_id

  validates_by_schema

  def to_s
    title || super
  end

  def path_args
    [person.primary_group, person, self]
  end

  private

  def attachment_prepare_print
    attachment&.dispatch!
  end
end
