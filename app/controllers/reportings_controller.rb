# app/controllers/reportings_controller.rb
class ReportingsController < ApplicationController
  skip_authorization_check

  def hours_approval
    load_hours(approved_status: [nil, false])

    respond_to do |format|
      format.html
      format.json { render json: @hour_data }
      format.js
    end
  end

  def update_hours_approval
    params[:approved_status]&.each do |hour_id, status|
      hour = Hour.find_by(id: hour_id)
      hour.update(approved_status: status.present?) if hour
    end

    respond_to do |format|
      format.html { redirect_to hours_approval_reportings_path, notice: "Hours updated successfully." }
      format.js # This will render `update_hours_approval.js.erb`
    end
  end

  def hours_summary
    load_hours(approved_status: true)

    person_ids = get_person_ids

    @total_volunteer_hours = Hour.where(person_id: person_ids)
                                 .where(approved_status: true)
                                 .sum(:volunteer_hours)
  end

  def download_hours
    respond_to do |format|
      format.csv { send_data generate_csv, filename: "approved_hours_#{Date.today}.csv" }
      format.pdf { send_data generate_pdf, filename: "approved_hours_#{Date.today}.pdf" }
    end
  end

  private

  def load_hours(approved_status:)
    person_ids = get_person_ids

    hours = Hour.includes(:person, :event)
                .where(person_id: person_ids)
                .where(approved_status: approved_status)

    @hour_data = format_hour_data(hours)
    apply_filters!
    
    current_year = Time.current.year
    @years = (current_year - 5..current_year).to_a.reverse
    @roles = @hour_data.flat_map { |h| h[:role].split(", ") }.uniq
    @unique_user_names = @hour_data.map { |h| h[:user_name] }.uniq
  end

  def format_hour_data(hours)
    hours.map do |hour|
      {
        hour_id: hour.id,
        user_name: hour.person.first_name,
        name: hour.event_id ? hour.event.name : hour.custom_item,
        date: hour.event_id ? "#{hour.event.application_opening_at} - #{hour.event.application_closing_at}" : hour.custom_item_date,
        role: hour.event_id ? hour.event.groups.map(&:name).join(", ") : hour.custom_item,
        hours: hour.volunteer_hours,
      }
    end
  end

  def apply_filters!
    if params[:year].present?
      @hour_data.select! { |h| h[:date].include?(params[:year]) }
    end

    if params[:role].present?
      @hour_data.select! { |h| h[:role].downcase.include?(params[:role].downcase) }
    end

    if params[:user].present?
      @hour_data.select! { |h| h[:user_name].downcase.include?(params[:user].downcase) }
    end
  end

  def get_person_ids
    roles = if current_user.id == 1
      Role.where(person_id: current_user.id) # Returns an array of roles
    else
      Role.where(person_id: current_user.id, type: 'Group::Region::Administrator') # Could return multiple roles
    end
  
    return [] if roles.empty? # Handle case where no roles are found
  
    group_ids = roles.pluck(:group_id) # Get all group_ids from roles
    @myGroups = Group.where(id: group_ids) # Store all related groups
  
    child_group_ids = group_ids.flat_map { |group_id| get_child_groups(group_id) }.uniq # Collect child group IDs for all roles
  
    Role.where(group_id: child_group_ids).pluck(:person_id) # Get person IDs from child groups
  end

  def get_topmost_parent(group_id)
    group = Group.find_by(id: group_id)
    return nil unless group
  
    while group.parent_id.present? && group.parent_id != 1
      group = Group.find_by(id: group.parent_id)
    end
  
    group
  end

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

  def generate_csv
    person_ids = get_person_ids
    hours = Hour.includes(:person, :event)
                .where(person_id: person_ids)
                .where(approved_status: true)
    hour_data = format_hour_data(hours)

    CSV.generate(headers: true) do |csv|
      csv << ['Number', 'Action Center', 'Event Name', 'Event Year', 'Volunteer Name', 'Volunteer Hours'] # Header row
      hour_data.each_with_index do |p, index|
        csv << [index + 1, p[:action_center], p[:name], p[:date], p[:user_name], p[:hours]]
      end
    end
  end

  def generate_pdf
    person_ids = get_person_ids
    hours = Hour.includes(:person, :event)
                .where(person_id: person_ids)
                .where(approved_status: true)
    hour_data = format_hour_data(hours)
    # Assuming you have a PDF generation library like Prawn
    pdf = Prawn::Document.new
    pdf.text "Approved Hours Summary", size: 20, style: :bold
    pdf.move_down 20

    pdf.table([['Number', 'Action Center', 'Event Name', 'Event Year', 'Volunteer Name', 'Volunteer Hours']] + 
              hour_data.each_with_index.map { |p, index| [index + 1, p[:action_center], p[:name], p[:date], p[:user_name], p[:hours]] })

    pdf.render
  end
end