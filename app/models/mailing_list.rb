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
  
  
  validates :mail_name, uniqueness: { case_sensitive: false },
                        format: /[a-z0-9\-\_\.]+/,
                        allow_blank: true
  validate :assert_mail_name_is_not_protected

  
  
  def to_s
    name
  end
  
  def subscribed?(person)
    people.where(id: person.id).exists?
  end
  
  def people
    condition = OrCondition.new
    # person subscribers
    condition.or("subscriptions.subscriber_type = ? AND " <<
                 "subscriptions.excluded = ? AND " <<
                 "subscriptions.subscriber_id = people.id",
                 Person.sti_name,
                 false)
                 
    # event subscribers
    condition.or("subscriptions.subscriber_type = ? AND " <<
                 "subscriptions.subscriber_id = event_participations.event_id AND " <<
                 "event_participations.active = ?",
                 Event.sti_name,
                 true)
                 
    # group subscribers
    condition.or("subscriptions.subscriber_type = ? AND " <<
                 "subscriptions.subscriber_id = sub_groups.id AND " <<
                 "groups.lft >= sub_groups.lft AND groups.rgt <= sub_groups.rgt AND " <<
                 "roles.type = related_role_types.role_type",
                 Group.sti_name)
                 
    Person.only_public_data.
           joins("LEFT JOIN roles ON people.id = roles.person_id").
           joins("LEFT JOIN groups ON roles.group_id = groups.id").
           joins("LEFT JOIN event_participations ON event_participations.person_id = people.id").
           joins(", subscriptions ").
           joins("LEFT JOIN groups sub_groups " << 
                 "ON subscriptions.subscriber_type = 'Group'" << 
                 "AND subscriptions.subscriber_id = sub_groups.id ").
           joins("LEFT JOIN related_role_types " << 
                 "ON related_role_types.relation_type = 'Subscription' " <<
                 "AND related_role_types.relation_id = subscriptions.id").
           where(subscriptions: { mailing_list_id: id }).
           where("people.id NOT IN (#{subscriptions.select(:subscriber_id).where(excluded: true, subscriber_type: Person.sti_name).to_sql})").
           where(condition.to_a).
           uniq
  end
  
  private
  
  def assert_mail_name_is_not_protected
    if mail_name? && main = Settings.email.retriever.config.user_name.presence
      if mail_name.downcase == main.split('@', 2).first.downcase
        errors.add(:mail_name, "'#{mail_name}' darf nicht verwendet werden")
      end
    end
  end
end
