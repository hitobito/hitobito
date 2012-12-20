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
  
  
  belongs_to :mailing_list
  
  belongs_to :subscriber, polymorphic: true
  
  has_many :related_role_types, as: :relation, dependent: :destroy
  
  # TODO: validate at least one related_role_type if subscriber_type == Group
  
end
