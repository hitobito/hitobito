# == Schema Information
#
# Table name: mailing_lists
#
#  id                   :integer          not null, primary key
#  name                 :string(255)      not null
#  group_id             :integer          not null
#  description          :text
#  publisher            :string(255)
#  mail_name            :string(255)
#  additional_sender    :string(255)
#  subscribable         :boolean          default(FALSE), not null
#  subscribers_may_post :boolean          default(FALSE), not null
#

class MailingList < ActiveRecord::Base
  
  attr_accessible :name, :description, :publisher, :mail_name, 
                  :additional_sender, :subscribable, :subscribers_may_post
                  
  
  belongs_to :group
  
  has_many :subscriptions, dependent: :destroy
  
  
  def to_s
    name
  end
  
end
