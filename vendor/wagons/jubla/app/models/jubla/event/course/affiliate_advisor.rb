module Jubla::Event::Course::AffiliateAdvisor
  extend ActiveSupport::Concern
  
  included do

    attr_accessible :advisor_id
    attr_accessor :advisor_id

    self.role_types += [Role::Advisor]

    after_save :create_advisor

  end

  def advisor
    @advisor ||= advisor_participation.try(:person)
  end

  def advisor_id
    @advisor_id ||= advisor.try(:id)
  end

  def advisor_participation
    @advisor_participation ||= participations.joins(:roles).where(event_roles: {type: Role::Advisor.sti_name}).first
  end

  private
  def create_advisor
    if advisor_participation.try(:person_id) != advisor_id
      if advisor_participation
        advisor_participation.roles.where(event_roles: {type: Role::Advisor.sti_name}).first.destroy
        @advisor_participation = nil # remove it from cache to
      end
      if advisor_id.present?
        participation = participations.where(person_id: advisor_id).first_or_create
        role = Role::Advisor.new
        role.participation = participation
        role.save!
      end
    end
  end
  
  module Role
    class Advisor < ::Event::Role
     
      self.permissions = [:contact_data]
      self.restricted = true
      self.affiliate = true
    
    end
  end

end
