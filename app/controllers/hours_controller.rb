# app/controllers/hours_controller.rb
class HoursController < ApplicationController
  skip_authorization_check

  def approve
    hours = Hour.where.not(hours: { custom_item: [nil, ''] })
            .where(person_id: current_user.id)

    hours_array = hours.map do |hour_record|
      {
        name: hour_record.custom_item,
        formatted_date_range: hour_record.custom_item_date,
        group_names: hour_record.custom_item,
        hours: hour_record.volunteer_hours,
        hours_id: hour_record.id,
        submitted_status: hour_record.submitted_status,
      }
    end

    events = Event
      .joins(:participations)
      .where(event_participations: { person_id: current_user.id })
      .left_joins(:hours)
      .left_joins(:groups)

    events_with_hours = events.map do |event|
      hours_record = event.hours.find_by(person_id: current_user.id)
      {
        name: event.name,
        formatted_date_range: "#{event.application_opening_at} - #{event.application_closing_at}",
        group_names: event.groups.map(&:name).join(", "),
        hours: hours_record ? hours_record.volunteer_hours : (event.event_hours == "" ? 0 : event.event_hours.to_i),
        hours_id: hours_record ? hours_record.id : event.id,
        submitted_status: hours_record ? hours_record.submitted_status : false,
        approved_status: hours_record ? hours_record.approved_status : false
      }
    end

    @combined_array = hours_array + events_with_hours
    # Calculate the total hours for the current user
    @total_volunteer_hours = Hour.where(person_id: current_user.id).sum(:volunteer_hours)

    respond_to do |format|
      format.html
      format.json { render json: { combined_array: @combined_array, total_volunteer_hours: @total_volunteer_hours } }
    end
  end

  def bulk_submit_for_event
    insert_event_ids = params[:insert_selected] || []
    delete_event_ids = params[:delete_selected] || []
    hours_params = params[:hours] || {}

    # Handle Insert Logic
    if insert_event_ids.any?
      insert_event_ids.each do |hours_id|
        next if hours_params[hours_id].to_f <= 0

        Hour.create!(
          event_id: hours_id,
          person_id: current_user.id,
          volunteer_hours: hours_params[hours_id].to_f,
          submitted_status: true
        )
      end
    end

    # Handle Delete Logic
    if delete_event_ids.any?
      delete_event_ids.each do |hours_id|
        hour_record = Hour.find_by(event_id: hours_id, person_id: current_user.id)

        unless hour_record
          hour_record = Hour.find_by(id: hours_id, person_id: current_user.id)
        end

        hour_record.destroy
      end
    end

    @success = true

    redirect_to approve_hours_path
  end

  def new_submission
    @hourModel = Hour.new
  end
  
  def submit_additional_event
    @hourModel = Hour.new
    
    # Extract parameters manually
    custom_item = params[:hour][:custom_item]
    start_date = params[:hour][:start_date]
    end_date = params[:hour][:end_date] ? params[:hour][:end_date] : ''

    # Validation errors hash
    @errors = {}

    # Custom validation checks
    @errors[:custom_item] = "Description cannot be empty." if custom_item.blank?
    @errors[:start_date] = "Start date is required." if start_date.blank?

    if start_date.present? && end_date.present? && start_date > end_date
      @errors[:start_date] = "Start date cannot be later than end date."
    end

    if @errors.any?
      render :new_submission
      return
    end

    @hour = Hour.new(
      person_id: current_user.id,
      volunteer_hours: params[:volunteer_hours].to_f,
      custom_item: custom_item,
      submitted_status: true,
      custom_item_date: "#{start_date} - #{end_date}"
    )

    if @hour.save
      flash[:notice] = "Additional hours submitted successfully."
      redirect_to approve_hours_path
    else
      flash.now[:alert] = "There was an issue submitting additional hours."
      render :new_submission
    end
  end
  
  def delete_event
    @hour = Hour.find(params[:id])
    
    if @hour.volunteer_hours == 0 && @hour.submitted_status
      @hour.destroy

      flash[:notice] = "Additional hour deleted successfully."
      redirect_to approve_hours_path
    else
      flash.now[:alert] = "here was an issue sdeleting hour."
      redirect_to approve_hours_path
    end
  end
  
  def hours_summary
  end

  private
end