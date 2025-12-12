#  Copyright (c) 2018 - 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
class ServiceToken < ActiveRecord::Base
  include I18nEnums

  belongs_to :layer, class_name: "Group", foreign_key: :layer_group_id
  has_many :cors_origins, as: :auth_method, dependent: :delete_all
  accepts_nested_attributes_for :cors_origins, allow_destroy: true

  before_validation :generate_token!, on: :create

  devise :timeoutable

  validates :token, uniqueness: {case_sensitive: false}, presence: true
  validates :name, uniqueness: {scope: :layer_group_id, case_sensitive: false}, presence: true
  validates_by_schema

  def to_s
    name
  end

  PERMISSIONS = %w[layer_read
    layer_and_below_read
    layer_full
    layer_and_below_full]

  i18n_enum :permission, PERMISSIONS, queries: true

  # Required as a substitute user for PeopleFilter and JSON Api
  # with PersonFetchables and in other places
  def dynamic_user
    Person.new do |p|
      role = Role.new
      role.group = layer
      role.permissions = [permission.to_sym]
      p.roles = [role]
      p.instance_variable_set(:@service_token, self)
    end
  end

  def dynamic_user_ability
    @dynamic_user_ability ||= Ability.new(dynamic_user)
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
