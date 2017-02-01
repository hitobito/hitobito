# encoding: utf-8

#  Copyright (c) 2012-2016, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito_dsj and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_dsj.

class Person::Note < ActiveRecord::Base

  default_scope { order(created_at: :desc) }

  ### ASSOCIATIONS

  belongs_to :person
  belongs_to :author, class_name: 'Person'

  ### VALIDATIONS

  validates :text, presence: true

  def to_s
    text.present? && text.sub("\n", ' ')[0..9] + (text.length > 10 ? '...' : '')
  end

end
