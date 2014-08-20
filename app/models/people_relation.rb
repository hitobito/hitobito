# encoding: utf-8

#  Copyright (c) 2014, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.


# == Schema Information
#
# Table name: people_relations
#
#  id      :integer          not null, primary key
#  head_id :integer          not null
#  tail_id :integer          not null
#  kind    :string(255)      not null
#
# Relates two people together. Every relation has an opposite that is created, updated and deleted
# at the same time.
class PeopleRelation < ActiveRecord::Base

  KIND_TRANSLATION_KEY = 'activerecord.attributes.people_relation.kinds'

  class_attribute :kind_opposites
  self.kind_opposites = {}

  # Set this attribute to true if a persistent action should not affect the opposite as well
  attr_accessor :no_opposite

  ### ASSOCIATIONS

  belongs_to :head, class_name: 'Person'
  belongs_to :tail, class_name: 'Person'

  ### VALIDATIONS

  validates :kind, inclusion: { in: ->(_) { possible_kinds } }
  validate :assert_head_and_tail_are_different

  ### CALLBACKS

  after_create :create_opposite
  before_update :remember_opposite
  after_update :update_opposite
  after_destroy :destroy_opposite

  scope :list, -> { includes(:tail).references(:tail).merge(Person.order_by_name) }

  class << self

    def possible_kinds
      kind_opposites.keys
    end

  end

  def translated_kind
    I18n.t("#{KIND_TRANSLATION_KEY}.#{kind.downcase}", default: kind)
  end

  def opposite_kind
    kind_opposites.fetch(kind)
  end

  def opposite
    PeopleRelation.where(new_record? ? opposite_attrs : old_opposite_attrs).first
  end

  private

  def assert_head_and_tail_are_different
    if head_id == tail_id
      errors.add(:tail_id, :must_not_be_equal_to_head)
    end
  end

  def create_opposite
    unless no_opposite
      o = PeopleRelation.new(opposite_attrs)
      o.no_opposite = true
      o.save!
    end
  end

  def destroy_opposite
    unless no_opposite
      o = opposite
      o.no_opposite = true
      o.destroy
    end
  end

  def remember_opposite
    unless no_opposite
      @old_opposite = opposite
    end
  end

  def update_opposite
    if @old_opposite
      @old_opposite.no_opposite = true
      @old_opposite.update!(opposite_attrs)
      @old_opposite = nil
    end
  end

  def opposite_attrs
    { head_id: tail_id, tail_id: head_id, kind: opposite_kind }
  end

  def old_opposite_attrs
    { head_id: tail_id_change ? tail_id_change.first : tail_id,
      tail_id: head_id,
      kind: kind_change ? kind_opposites.fetch(kind_change.first) : opposite_kind }
  end

end
