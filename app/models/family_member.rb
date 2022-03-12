# frozen_string_literal: true

#  Copyright (c) 2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# The different kinds could be a "type" and be solved with STI-classes. Once
# we support multiple types of FamilyMembers, we should think about using STI
# to isolate the differences.
#
# FamilyMember::Sibling
#   - has same parents as other siblings (once they have parents)
#   - are not modeled to cover halfsiblings
#   - is sibling to all siblings of the same family
#   - can leave family if all siblings are removed (to correct wrong assingment)

class FamilyMember < ApplicationRecord
  # TODO: extract exception to its own file
  class FamilyKeyMismatch < StandardError
    def initialize(family)
      super <<~MESSAGE
        Attempted to create a family-bond between
        #{family.person} and #{family.other},
        but they seem to already to belong to different
        families.

        Both people have a "family_key", but not the same.

        Data:
        - Person: #{family.person_id}
        - Other: #{family.other_id}
        - Relation: #{family.kind} / #{family.kind_label}
      MESSAGE
    end
  end

  # TODO: extract exception to its own file
  class NoRelationTransitivenessDefined < StandardError
    def initialize(family)
      super <<~MESSAGE
        The given kind of FamilyMember (#{family.kind_label})
        has no defined behaviour to handle the transitive
        relation.
      MESSAGE
    end
  end

  # TODO: extract exception to its own file
  class NoRelationInversionDefined < StandardError
    def initialize(family)
      super <<~MESSAGE
        The given kind of FamilyMember (#{family.kind_label})
        has no defined behaviour to handle the inverse
        relation.
      MESSAGE
    end
  end

  include I18nEnums

  i18n_enum :kind, %w(sibling).freeze # could be: parent child sibling

  belongs_to :person
  belongs_to :other, class_name: 'Person'

  before_validation :create_or_copy_family_key, on: :create
  after_create :create_inverse_relation
  after_create :create_transitive_relations
  after_destroy :destroy_inverse_relation

  validates_by_schema

  def inspect
    "<#FamilyMember #{id}: #{self} [#{family_key}]>"
  end

  def to_s
    "#{person} --(#{kind_label})--> #{other}"
  end

  private

  def create_or_copy_family_key # rubocop:disable Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/AbcSize,Metric/PerceivedComplexity
    return false if person.blank? || other.blank?

    if person.family_key.blank? && other.family_key.blank?
      self.family_key = new_family_key
      copy_family_key(self, person, other)

    elsif person.family_key.present? && other.family_key.blank?
      copy_family_key(person, other, self)

    elsif person.family_key.blank? && other.family_key.present?
      copy_family_key(other, person, self)

    elsif person.family_key == other.family_key
      copy_family_key(person, self)

    else
      raise FamilyKeyMismatch, self
    end

    true
  end

  def create_transitive_relations
    raise NoRelationTransitivenessDefined, self if kind.to_sym != :sibling

    # find siblings (as scope)
    siblings = self.class
                   .where(family_key: family_key, kind: :sibling)
                   .where.not(person_id: person_id)

    # create links between siblings (given a scope)
    siblings.pluck(:person_id).each do |sibling_id|
      attrs = { person: person, other_id: sibling_id, kind: :sibling }
      self.class.create!(attrs.merge(family_key: family_key)) unless self.class.exists?(attrs)
    end
  end

  def create_inverse_relation
    raise NoRelationInversionDefined, self if kind.to_sym != :sibling

    # reverse the relationship, choosing the right kind
    self.class.find_or_create_by!(
      person: other, kind: :sibling, other: person, family_key: family_key
    )
  end

  def destroy_inverse_relation
    raise NoRelationInversionDefined, self if kind.to_sym != :sibling

    # find the reversed the relationship, choosing the right kind
    self.class.find_by(
      person: other, kind: :sibling, other: person, family_key: family_key
    ).delete # skip callbacks to avoid looping
  end

  def copy_family_key(from, *to_people)
    to_people.each do |to|
      if to.new_record?
        to.family_key = from.family_key
      else
        to.update_column(:family_key, from.family_key) # rubocop:disable Rails/SkipsModelValidations
      end
    end
  end

  def new_family_key
    loop do
      new_key = SecureRandom.uuid
      break new_key unless self.class.where(family_key: new_key).exists?
    end
  end
end
