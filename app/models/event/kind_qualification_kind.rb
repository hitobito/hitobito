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
#  event_kind_id         :integer          not null
#  qualification_kind_id :integer          not null
#  category              :string(255)      not null
#  role                  :string(255)      not null
#

class Event::KindQualificationKind < ActiveRecord::Base

  CATEGORIES = %w(qualification precondition prolongation)
  ROLES = %w(participant leader)


  ### ASSOCIATIONS

  belongs_to :event_kind, class_name: 'Event::Kind'
  belongs_to :qualification_kind


  ### VALIDATIONS

  validates :category, inclusion: { in: CATEGORIES }
  validates :role, inclusion: { in: ROLES }

end
