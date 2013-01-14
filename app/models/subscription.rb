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

  attr_accessible :subscriber_id

  include RelatedRoleType::Assigners


  ### ASSOCIATIONS

  belongs_to :mailing_list

  belongs_to :subscriber, polymorphic: true

  has_many :related_role_types, as: :relation, dependent: :destroy


  ### VALIDATIONS

  validates :related_role_types, presence: { if: lambda { |s| s.subscriber.is_a?(Group) } }

  validates :subscriber_id, uniqueness: { unless: lambda { |s| s.subscriber.is_a?(Group) },
                                          scope: [:mailing_list_id, :subscriber_type, :excluded] }


  ### INSTANCE METHODS

  def to_s
    string = subscriber.to_s
    if subscriber.is_a?(Group) && related_role_types.present?
      string << ' (' << related_role_types.join(', ') << ')'
    end
    string
  end

end
