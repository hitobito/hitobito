#  frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Wanderwege. This file is part of
#  hitobito_sww and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sww.class MessageTemplate < ApplicationRecord

# == Schema Information
#
# Table name: message_templates
#
#  id             :bigint           not null, primary key
#  body           :text
#  templated_type :string
#  title          :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  templated_id   :bigint
#
# Indexes
#
#  index_message_templates_on_templated  (templated_type,templated_id)
#
class MessageTemplate < ApplicationRecord
  belongs_to :templated, polymorphic: true

  validates :title, presence: true

  def option_for_select
    [title, id, data: {title: title, body: body}]
  end
end
