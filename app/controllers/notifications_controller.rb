# app/controllers/notifications_controller.rb
class NotificationsController < ApplicationController
  skip_authorization_check

  def event
    roles = if current_user.id == 1
      Role.where(person_id: current_user.id)
    else
      Role.where(person_id: current_user.id, type: 'Group::Region::Administrator')
    end
  
    return [] if roles.empty?
  
    group_ids = roles.pluck(:group_id)

    @events = Event.joins(:groups).where(groups: { id: group_ids }).distinct
  end

  def notify
    if params[:event_id].blank? || params[:event_subject].blank? || params[:event_body].blank?
      flash[:error] = "Event, Subject, and Body are required fields."
      redirect_to event_notifications_path and return
    end

    event = Event.find(params[:event_id])

    group_id = event.groups.pluck(:id)

    admin_person_ids = Role.where(group_id: group_id, type: 'Group::Region::Administrator').pluck(:person_id)

    admin_emails = Person.where(id: admin_person_ids).pluck(:email)  

    child_groups_id = get_child_groups(group_id)

    user_person_ids = Role.where(group_id: child_groups_id).where.not(type: 'Group::Region::Administrator').pluck(:person_id)

    if params[:recipient_type] == "approved_participants"
      user_person_ids = event.participations.where(person_id: user_person_ids).where.not(active: false).pluck(:person_id)
    else
      user_person_ids = event.participations.where(person_id: user_person_ids).pluck(:person_id)
    end

    user_emails = Person.where(id: user_person_ids).pluck(:email)

    # Get additional CC emails from form input
    additional_cc_emails = params[:event_email_cc].to_s.split(',').map(&:strip).reject(&:blank?)

    # Combine admin emails and additional CC emails
    cc_emails = (admin_emails + additional_cc_emails).uniq

    if user_emails.empty?
      flash[:error] = "No participants found to send the notification."
      redirect_to event_notifications_path and return
    end

    user_emails.each do |email|
      Event::NotificationMailer.event_notification(email, params[:event_subject], params[:event_body], cc: cc_emails).deliver_later
    end

    flash[:success] = "Notification sent successfully!"

    redirect_to event_notifications_path
  end

  private

  # Get all child group IDs recursively (ensure no duplicates)
  def get_child_groups(group_id, visited = Set.new)
    child_groups = []
    return child_groups if visited.include?(group_id) # Avoid processing the same group

    visited.add(group_id)
    child_groups << group_id # Include the current group first
    
    children = Group.where(parent_id: group_id)
    children.each do |child|
      # Recurse for each child
      child_groups += get_child_groups(child.id, visited)
    end
    child_groups
  end
end