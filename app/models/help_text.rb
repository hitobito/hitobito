# frozen_string_literal: true

#  Copyright (c) 2019, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class HelpText < ActiveRecord::Base

  include Globalized
  translates :body

  validates :key, uniqueness: true
  validates_by_schema

  def to_s(_format = :default)
    key
  end

end
