# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: groups
#
#  id             :integer          not null, primary key
#  parent_id      :integer
#  lft            :integer
#  rgt            :integer
#  name           :string(255)      not null
#  short_name     :string(31)
#  type           :string(255)      not null
#  email          :string(255)
#  address        :string(1024)
#  zip_code       :integer
#  town           :string(255)
#  country        :string(255)
#  contact_id     :integer
#  created_at     :datetime
#  updated_at     :datetime
#  deleted_at     :datetime
#  layer_group_id :integer
#  creator_id     :integer
#  updater_id     :integer
#  deleter_id     :integer
#

class Group < ActiveRecord::Base

  MINIMAL_SELECT = %w(id name type parent_id lft rgt layer_group_id deleted_at).
                   collect { |a| "groups.#{a}" }

  include Group::Types
  include Group::NestedSet
  include Contactable

  acts_as_paranoid
  extend Paranoia::RegularScope

  ### ATTRIBUTES

  # All attributes actually used (and mass-assignable) by the respective STI type.
  # This must contain the superior attributes as well.
  class_attribute :used_attributes
  self.used_attributes = [:name, :short_name, :email, :contact_id,
                          :email, :address, :zip_code, :town, :country]

  # Attributes that may only be modified by people from superior layers.
  class_attribute :superior_attributes
  self.superior_attributes = []

  attr_readonly :type

  ### CALLBACKS

  before_save :reset_contact_info

  # Root group may not be destroyed
  protect_if :root?
  protect_if :children_without_deleted

  stampable stamper_class_name: :person, deleter: true

  ### ASSOCIATIONS

  belongs_to :contact, class_name: 'Person'

  has_many :roles, dependent: :destroy, inverse_of: :group
  has_many :people, through: :roles

  has_many :people_filters, dependent: :destroy

  has_and_belongs_to_many :events, after_remove: :destroy_orphaned_event

  has_many :mailing_lists, dependent: :destroy
  has_many :subscriptions, as: :subscriber, dependent: :destroy


  ### VALIDATIONS

  validates :email, format: Devise.email_regexp, allow_blank: true


  ### CLASS METHODS

  class << self

    # Is the given attribute used in the current STI class
    def attr_used?(attr)
      used_attributes.include?(attr)
    end

    # order groups by type. If a parent group is given, order the types
    # as they appear in possible_children, otherwise order them
    # hierarchically over all group types.
    def order_by_type(parent_group = nil)
      types = with_child_types(parent_group)
      if types.present?
        statement = 'CASE groups.type '
        types.each_with_index do |t, i|
          statement << "WHEN '#{t.sti_name}' THEN #{i} "
        end
        statement << 'END, '
      end
      reorder("#{statement} lft") # acts_as_nested_set default to new order
    end

    private

    def with_child_types(parent_group = nil)
      if parent_group
        [parent_group.class] + parent_group.possible_children
      else
        all_types
      end
    end

  end


  ### INSTANCE METHODS


  def to_s(_format = :default)
    name
  end

  def with_layer
    layer? ? [self] : [layer_group, self]
  end

  ## readers and query methods for contact info
  [:address, :town, :zip_code, :country].each do |attribute|
    [attribute, :"#{attribute}?"].each do |method|
      define_method(method) do
        (contact && contact.public_send(method)) || super()
      end
    end
  end

  # create alias to call it again
  alias_method :hard_destroy, :really_destroy!
  def really_destroy!
    # run nested_set callback on hard destroy
    destroy_descendants_without_paranoia
    # load events to destroy orphaned later
    list = events.to_a
    hard_destroy
    list.each { |e| destroy_orphaned_event(e) }
  end

  def decorator_class
    GroupDecorator
  end

  private

  def destroy_orphaned_event(event)
    if event.group_ids.blank? || event.group_ids == [id]
      event.destroy!
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
