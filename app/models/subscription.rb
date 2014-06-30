# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: subscriptions
#
#  id              :integer          not null, primary key
#  mailing_list_id :integer          not null
#  subscriber_id   :integer          not null
#  subscriber_type :string(255)      not null
#  excluded        :boolean          default(FALSE), not null
#

class Subscription < ActiveRecord::Base

  include RelatedRoleType::Assigners


  ### ASSOCIATIONS

  belongs_to :mailing_list

  belongs_to :subscriber, polymorphic: true

  has_many :related_role_types, as: :relation, dependent: :destroy


  ### VALIDATIONS

  validates :related_role_types, presence: { if: ->(s) { s.subscriber.is_a?(Group) } }

  validates :subscriber_id, uniqueness: { unless: ->(s) { s.subscriber.is_a?(Group) },
                                          scope: [:mailing_list_id, :subscriber_type, :excluded] }


  ### INSTANCE METHODS

  def to_s(format = :default)
    string = subscriber.to_s(format).dup
    if subscriber.is_a?(Group) && related_role_types.present?
      string = subscriber.with_layer.join(' / ')
      string << ' (' << related_role_types.join(', ') << ')'
    end
    string
  end

end
