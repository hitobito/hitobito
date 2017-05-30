# encoding: utf-8

#  Copyright (c) 2012-2016, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito_dsj and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_dsj.
# == Schema Information
#
# Table name: notes
#
#  id           :integer          not null, primary key
#  subject_id   :integer          not null
#  author_id    :integer          not null
#  text         :text
#  created_at   :datetime
#  updated_at   :datetime
#  subject_type :string
#

class Note < ActiveRecord::Base

  ### ASSOCIATIONS

  belongs_to :subject, polymorphic: true
  belongs_to :author, class_name: 'Person'

  ### VALIDATIONS

  validates :text, presence: true

  scope :list, -> { order(created_at: :desc) }

  def to_s
    text.to_s.delete("\n").truncate(10)
  end

end
