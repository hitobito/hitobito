# frozen_string_literal: true

#  Copyright (c) 2012-2021, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: notes
#
#  id           :integer          not null, primary key
#  subject_type :string(255)
#  text         :text(16777215)
#  created_at   :datetime
#  updated_at   :datetime
#  author_id    :integer          not null
#  subject_id   :integer          not null
#
# Indexes
#
#  index_notes_on_subject_id  (subject_id)
#

class Note < ActiveRecord::Base

  ### ASSOCIATIONS

  belongs_to :subject, polymorphic: true
  belongs_to :author, class_name: 'Person'

  ### VALIDATIONS

  validates_by_schema
  validates :text, presence: true
  validates :subject_type, inclusion: %w(Person Group)

  scope :list, -> { order(created_at: :desc) }

  class << self
    def below_in_layer(group)
      groups = Group.where(layer_group_id: group.layer_group_id, deleted_at: nil).
          where('lft >= ?', group.lft).where('rgt <= ?', group.rgt)
      person_ids = groups.left_joins(:roles).select(Role.arel_table[:person_id])

      # All notes that belong to one of the groups...
      where(subject_type: Group.sti_name, subject_id: groups.select(:id)).
          # ... or to a person in one of the groups
          or(where(subject_type: Person.sti_name, subject_id: person_ids)).
          distinct
    end
  end

  def to_s
    text.to_s.delete("\n").truncate(10)
  end

end
