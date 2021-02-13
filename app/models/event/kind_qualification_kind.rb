# encoding: utf-8

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: event_kind_qualification_kinds
#
#  id                    :integer          not null, primary key
#  category              :string(255)      not null
#  grouping              :integer
#  role                  :string(255)      not null
#  event_kind_id         :integer          not null
#  qualification_kind_id :integer          not null
#
# Indexes
#
#  index_event_kind_qualification_kinds_on_category  (category)
#  index_event_kind_qualification_kinds_on_role      (role)
#

class Event::KindQualificationKind < ActiveRecord::Base

  CATEGORIES = %w(qualification precondition prolongation).freeze
  ROLES = %w(participant leader).freeze

  class << self

    def grouped_qualification_kind_ids(category, role)
      where(category: category, role: role).
        pluck(:grouping, :qualification_kind_id).
        group_by(&:first).
        map { |_, v| v.map(&:last) }
    end

  end


  ### ASSOCIATIONS

  belongs_to :event_kind, class_name: "Event::Kind"
  belongs_to :qualification_kind


  ### VALIDATIONS

  validates_by_schema
  validates :category, inclusion: { in: CATEGORIES }
  validates :role, inclusion: { in: ROLES }

end
