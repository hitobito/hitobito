#  Copyright (c) 2018, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: service_tokens
#
#  id             :integer          not null, primary key
#  layer_group_id :integer
#  name           :string(255)
#  description    :text(65535)
#  token          :string(255)
#  last_access    :datetime
#  people         :boolean
#  people_below   :boolean
#  groups         :boolean
#  events         :boolean
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class ServiceToken < ActiveRecord::Base

  belongs_to :layer, class_name: 'Group', foreign_key: :layer_group_id

  before_validation :generate_token!, on: :create

  validates :token, uniqueness: true, presence: true
  validates :name, uniqueness: { scope: :layer_group_id }, presence: true
  validates_by_schema

  def to_s
    name
  end

  private

  def generate_token!
    loop do
      token = Devise.friendly_token(50)
      unless ServiceToken.exists?(token: token)
        self.token = token
        break
      end
    end
  end

end
