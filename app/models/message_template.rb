#  frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Wanderwege. This file is part of
#  hitobito_sww and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sww.class MessageTemplate < ApplicationRecord

class MessageTemplate < ApplicationRecord
  belongs_to :templated, polymorphic: true

  validates :title, presence: true

  def option_for_select(data_map: {title: :title, body: :description})
    [title, id, data: {data_map[:title] => title, data_map[:body] => body}]
  end
end
