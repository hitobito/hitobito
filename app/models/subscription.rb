#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: subscriptions
#
#  id              :integer          not null, primary key
#  excluded        :boolean          default(FALSE), not null
#  subscriber_type :string(255)      not null
#  mailing_list_id :integer          not null
#  subscriber_id   :integer          not null
#
# Indexes
#
#  index_subscriptions_on_mailing_list_id                    (mailing_list_id)
#  index_subscriptions_on_subscriber_id_and_subscriber_type  (subscriber_id,subscriber_type)
#

class Subscription < ApplicationRecord
  include RelatedRoleType::Assigners

  scope :people, -> { where(subscriber_type: Person.sti_name) }
  scope :groups, -> { where(subscriber_type: Group.sti_name) }
  scope :events, -> { where(subscriber_type: Event.sti_name) }
  scope :tagged, -> { joins(:subscription_tags) }

  ### ASSOCIATIONS

  belongs_to :mailing_list

  belongs_to :subscriber, polymorphic: true

  has_many :subscription_tags, dependent: :destroy

  has_many :related_role_types, as: :relation, dependent: :destroy

  ### VALIDATIONS

  validates_by_schema
  validates :related_role_types, presence: {if: ->(s) { s.subscriber.is_a?(Group) }}

  validates :subscriber_id, uniqueness: {unless: ->(s) { s.subscriber.is_a?(Group) },
                                         scope: [:mailing_list_id, :subscriber_type, :excluded],}
  validates :subscriber_id, inclusion: {if: ->(s) { s.subscriber.is_a?(Group) },
                                        in: ->(s) { s.possible_groups.pluck(:id) },
                                        message: :group_not_allowed,}
  validates :subscriber_id, inclusion: {if: ->(s) { s.subscriber.is_a?(Event) },
                                        in: ->(s) { s.possible_events.pluck(:id) },
                                        message: :event_not_allowed,}

  ### INSTANCE METHODS

  def to_s(format = :default)
    if subscriber.is_a?(Group)
      subscriber.with_layer.join(" / ")
    else
      subscriber.to_s(format).dup
    end
  end

  def possible_events
    Event
      .joins(:groups, :dates)
      .where("event_dates.start_at >= ?", earliest_possible_event_date)
      .where(groups: {id: possible_event_groups})
  end

  def possible_groups
    mailing_list.group.self_and_descendants.without_deleted
  end

  def grouped_role_types
    result = {}
    role_classes = related_role_types.map(&:role_class)
    Role::TypeList.new(subscriber.class).each do |layer, groups|
      groups_result = {}
      groups.each do |group, role_types|
        role_types_result = role_types.select { |rt| role_classes.include?(rt) }
        groups_result[group] = role_types_result if role_types_result.present?
      end
      result[layer] = groups_result if groups_result.present?
    end
    result
  end

  def included_subscription_tags_ids
    subscription_tags.included.map(&:tag).pluck(:id)
  end

  def excluded_subscription_tags_ids
    subscription_tags.excluded.map(&:tag).pluck(:id)
  end

  private

  def earliest_possible_event_date
    Time.zone.now.prev_year.beginning_of_year
  end

  # this may be different from possible_groups in wagons
  def possible_event_groups
    mailing_list.group.self_and_descendants
  end
end
