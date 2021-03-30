# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
#
# == Schema Information
#
# Table name: assignments
#
#  id              :bigint           not null, primary key
#  attachment_type :string(255)
#  description     :text(65535)      not null
#  read_at         :date
#  title           :string(255)      not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  attachment_id   :integer
#  creator_id      :bigint           not null
#  person_id       :bigint           not null
#
# Indexes
#
#  index_assignments_on_creator_id  (creator_id)
#  index_assignments_on_person_id   (person_id)
#

class Assignment < ActiveRecord::Base
  ATTACHMENT_TYPES = [Message::Letter, Message::LetterWithInvoice].freeze
  include I18nEnums

  belongs_to :person
  belongs_to :creator, class_name: 'Person'
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
