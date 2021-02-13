#  Copyright (c) 2018, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: service_tokens
#
#  id                   :integer          not null, primary key
#  description          :text(16777215)
#  event_participations :boolean          default(FALSE), not null
#  events               :boolean          default(FALSE)
#  groups               :boolean          default(FALSE)
#  invoices             :boolean          default(FALSE), not null
#  last_access          :datetime
#  mailing_lists        :boolean          default(FALSE), not null
#  name                 :string(255)      not null
#  people               :boolean          default(FALSE)
#  people_below         :boolean          default(FALSE)
#  token                :string(255)      not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  layer_group_id       :integer          not null
#

class ServiceToken < ActiveRecord::Base
  belongs_to :layer, class_name: "Group", foreign_key: :layer_group_id

  before_validation :generate_token!, on: :create

  validates :token, uniqueness: {case_sensitive: false}, presence: true
  validates :name, uniqueness: {scope: :layer_group_id, case_sensitive: false}, presence: true
  validates_by_schema

  def to_s
    name
  end

  # Required so PeopleFilter can use PersonFetchables
  def dynamic_user
    Person.new do |p|
      role = Role.new
      role.group = layer
      role.permissions = [:layer_and_below_full]
      p.roles = [role]
    end
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
