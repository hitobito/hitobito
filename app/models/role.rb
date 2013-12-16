# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: roles
#
#  id         :integer          not null, primary key
#  person_id  :integer          not null
#  group_id   :integer          not null
#  type       :string(255)      not null
#  label      :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  deleted_at :datetime
#

class Role < ActiveRecord::Base

  acts_as_paranoid

  include Role::Types
  include NormalizedLabels
  include TypeId

  attr_accessible :label

  # If these attributes should change, create a new role instance instead.
  attr_readonly :person_id, :group_id, :type

  ### ASSOCIATIONS

  belongs_to :person
  belongs_to :group

  ### VALIDATIONS

  validates :type, presence: true
  validate :assert_type_is_allowed_for_group, on: :create


  ### CALLBACKS

  after_create :set_contact_data_visible
  after_create :set_first_primary_group
  after_destroy :reset_contact_data_visible
  after_destroy :reset_primary_group



  ### CLASS METHODS

  class << self

    # Is the given attribute used in the current STI class
    def attr_used?(attr)
      [:default, :superior].any? do |role|
        accessible_attributes(role).include?(attr)
      end
    end
  end


  ### INSTANCE METHODS

  def to_s
    model_name = self.class.label
    string = label? ? "#{label} (#{model_name})" : model_name
  end

  # Soft destroy if older than certain amount of days, hard if younger
  def destroy
    if old_enough_to_archive?
      super
    else
      destroy!
    end
  end

  private

  # If this role has contact_data permissions, set the flag on the person
  def set_contact_data_visible
    if becomes(type.constantize).permissions.include?(:contact_data)
      person.update_column :contact_data_visible, true
    end
  end

  # If this role was the last one with contact_data permission, remove the flag from the person
  def reset_contact_data_visible
    if permissions.include?(:contact_data) &&
       !person.roles.collect(&:permissions).flatten.include?(:contact_data)
      person.update_column :contact_data_visible, false
    end
  end

  def set_first_primary_group
    if person.roles.count <= 1
      person.update_column :primary_group_id, group_id
    end
  end

  def reset_primary_group
    if person.primary_group_id == group_id && person.roles.where(group_id: group_id).count == 0
      person.update_column :primary_group_id, nil
    end
  end

  def assert_type_is_allowed_for_group
    if type && group && !group.role_types.collect(&:sti_name).include?(type)
      errors.add(:type, :type_not_allowed)
    end
  end

  def old_enough_to_archive?
    (Time.zone.now - created_at) > Settings.role.minimum_days_to_archive.days
  end
end
