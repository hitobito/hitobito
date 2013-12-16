# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: groups
#
#  id                  :integer          not null, primary key
#  parent_id           :integer
#  lft                 :integer
#  rgt                 :integer
#  name                :string(255)      not null
#  short_name          :string(31)
#  type                :string(255)      not null
#  email               :string(255)
#  address             :string(1024)
#  zip_code            :integer
#  town                :string(255)
#  country             :string(255)
#  contact_id          :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  deleted_at          :datetime
#  layer_group_id      :integer
#  bank_account        :string(255)
#  jubla_insurance     :boolean          default(FALSE), not null
#  jubla_full_coverage :boolean          default(FALSE), not null
#  parish              :string(255)
#  kind                :string(255)
#  unsexed             :boolean          default(FALSE), not null
#  clairongarde        :boolean          default(FALSE), not null
#  founding_year       :integer
#  creator_id             :integer
#  updater_id             :integer
#  deleter_id             :integer
#

class Group < ActiveRecord::Base

  MINIMAL_SELECT = %w(id name type parent_id lft rgt layer_group_id deleted_at).collect { |a| "groups.#{a}" }


  include Group::Types
  include Contactable

  acts_as_paranoid
  extend Paranoia::RegularScope

  ### ATTRIBUTES

  attr_accessible :name, :short_name, :email, :contact_id

  attr_readonly :type

  ### CALLBACKS

  after_create :set_layer_group_id
  after_create :create_default_children
  before_save :reset_contact_info

  # Root group may not be destroyed
  protect_if :root?
  protect_if :children_without_deleted

  stampable stamper_class_name: :person, deleter: true

  ### ASSOCIATIONS

  acts_as_nested_set dependent: :destroy


  belongs_to :contact, class_name: 'Person'

  has_many :roles, dependent: :destroy, inverse_of: :group
  has_many :people, through: :roles

  has_many :people_filters, dependent: :destroy

  has_and_belongs_to_many :events, after_remove: :destroy_orphaned_event

  has_many :mailing_lists, dependent: :destroy
  has_many :subscriptions, as: :subscriber, dependent: :destroy


  ### VALIDATIONS
  validates :email, format: Devise.email_regexp, allow_blank: true
  validate :assert_type_is_allowed_for_parent, on: :create


  ### INDEX

  define_partial_index do
    indexes name, short_name, sortable: true
    indexes email, address, zip_code, town, country

    indexes parent.name, as: :parent_name
    indexes parent.short_name, as: :parent_short_name
    indexes phone_numbers.number, as: :phone_number
    indexes social_accounts.name, as: :social_account

    where 'groups.deleted_at IS NULL'
  end


  ### CLASS METHODS

  class << self

    # Is the given attribute used in the current STI class
    def attr_used?(attr)
      [:default, :superior].any? do |role|
        accessible_attributes(role).include?(attr)
      end
    end

    # Attributes that may only be modified by people from superior layers
    def superior_attributes
      accessible_attributes(:superior).to_a - accessible_attributes(:default).to_a
    end

    # order groups by type. If a parent group is given, order the types
    # as they appear in possible_children, otherwise order them
    # hierarchically over all group types.
    def order_by_type(parent_group = nil)
      types = parent_group ? parent_group.possible_children : Group.all_types
      if types.present?
        statement = 'CASE groups.type '
        types.each_with_index do |t, i|
          statement << "WHEN '#{t.sti_name}' THEN #{i} "
        end
        statement << 'END, '
      end
      reorder("#{statement} name") # acts_as_nested_set default to new order
    end

  end


  ### INSTANCE METHODS


  # The hierarchy from top to bottom of and including this group.
  def hierarchy
    @hierarchy ||= self_and_ancestors
  end

  # The layer of this group.
  def layer_group
    layer ? self : layer_hierarchy.last
  end

  # The layer hierarchy from top to bottom of this group.
  def layer_hierarchy
    hierarchy.select { |g| g.class.layer }
  end

  # siblings with the same type
  def sister_groups
    self_and_sister_groups.where('id <> ?', id)
  end

  def self_and_sister_groups
    Group.without_deleted.
          where(parent_id: parent_id, type: type)
  end

  # siblings with the same type and all their descendant groups, including self
  def sister_groups_with_descendants
    Group.without_deleted.
          joins('LEFT JOIN groups AS sister_groups ' +
                'ON groups.lft >= sister_groups.lft AND groups.lft < sister_groups.rgt').
          where('sister_groups.type = ?', type).
          where(parent_id? ? ['sister_groups.parent_id = ?', parent_id] : 'sister_groups.parent_id IS NULL')
  end

  # The layer hierarchy without the layer of this group.
  def upper_layer_hierarchy
    if new_record?
      if parent
        if layer?
          parent.layer_hierarchy
        else
          parent.layer_hierarchy - [parent.layer_group]
        end
      else
        []
      end
    else
      layer_hierarchy - [layer_group]
    end
  end

  def to_s(format = :default)
    name
  end

  ## readers and query methods for contact info
  [:address, :town, :zip_code, :country].each do |attribute|
    define_method(attribute) do
      (contact && contact.public_send(attribute)) || super()
    end

    query_method = :"#{attribute}?"

    define_method(query_method) do
      (contact && contact.public_send(query_method)) || super()
    end
  end

  # create alias to call it again
  alias_method :hard_destroy, :destroy!
  def destroy!
    # run nested_set callback on hard destroy
    destroy_descendants_without_paranoia
    hard_destroy
    destroy_orphaned_events
  end

  def decorator_class
    GroupDecorator
  end

  private

  def assert_type_is_allowed_for_parent
    if type && parent && !parent.possible_children.collect(&:sti_name).include?(type)
      errors.add(:type, :type_not_allowed)
    end
  end

  def set_layer_group_id
    layer_group_id = self.class.layer ? id : parent.layer_group_id
    update_column(:layer_group_id, layer_group_id)
  end

  def create_default_children
    default_children.each do |group_type|
      child = group_type.new(name: group_type.label)
      child.parent = self
      child.save!
    end
  end

  def destroy_orphaned_events
    events.includes(:groups).each do |e|
      destroy_orphaned_event(e)
    end
  end

  def destroy_orphaned_event(event)
    if event.group_ids.blank? || event.group_ids == [id]
      event.destroy
    end
  end

  def reset_contact_info
    if contact
      clear_contacts = { address: nil, town: nil, zip_code: nil, country: nil }
      assign_attributes(clear_contacts)
    end
  end

  def children_without_deleted
    children.without_deleted
  end

  def destroy_descendants_with_paranoia
    # do not destroy descendants on soft delete
  end
  alias_method_chain :destroy_descendants, :paranoia

end
