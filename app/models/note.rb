# encoding: utf-8

#  Copyright (c) 2012-2016, Dachverband Schweizer Jugendparlamente. This file is part of
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
  belongs_to :author, class_name: "Person"

  ### VALIDATIONS

  validates_by_schema
  validates :text, presence: true

  scope :list, -> { order(created_at: :desc) }

  class << self
    def in_or_layer_below(group)
      joins("LEFT JOIN roles " \
            "ON roles.person_id = notes.subject_id AND notes.subject_type = '#{Person.sti_name}'").
        joins("INNER JOIN #{Group.quoted_table_name} " \
              "ON (#{Group.quoted_table_name}.id = notes.subject_id "\
                  "AND notes.subject_type = '#{Group.sti_name}') " \
              "OR (#{Group.quoted_table_name}.id = roles.group_id)").
        where(roles: { deleted_at: nil },
              groups: { deleted_at: nil, layer_group_id: group.layer_group_id }).
        where("#{Group.quoted_table_name}.lft >= :lft AND #{Group.quoted_table_name}.rgt <= :rgt",
              lft: group.lft, rgt: group.rgt).
        distinct
    end
  end

  def to_s
    text.to_s.delete("\n").truncate(10)
  end

end
