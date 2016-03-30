# encoding: utf-8

#  Copyright (c) 2012-2016, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito_dsj and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_dsj.

class Tag < ActiveRecord::Base

  belongs_to :taggable, polymorphic: true

  validates :name, uniqueness: { scope: [:taggable_id, :taggable_type],
                                 message: :must_be_unique }

  def to_s
    "#{name}: #{taggable}"
  end

end
