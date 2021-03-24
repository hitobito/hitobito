# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AssignmentsController < CrudController
  self.permitted_attrs = [:title, :description, :attachment_id, :person_id]

  before_action :set_read_at, only: :show, if: :assignment_assignee?

  after_create :enqueue_notification

  def new
    entry.person = default_assignee
    super
  end

  private

  def enqueue_notification
    Assignment::SendNotificationJob.new(entry).enqueue!
  end

  def path_args(entry)
    action_name.eql?('new') || entry.person_id.blank? ? super : entry.path_args
  end

  def assign_attributes
    super
    entry.creator_id = current_user.id
  end

  def set_read_at
    entry.update!(read_at: Time.zone.now) unless entry.read_at
  end

  def assignment_assignee?
    current_user.id == person.id
  end

  def find_entry
    person.assignments.find(params[:id])
  end

  def build_entry
    built_entry = super
    built_entry.attachment = Message::Letter.find(permitted_params[:attachment_id])
    built_entry
  end

  def person
    @person ||= group.people.find(params[:person_id])
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def default_assignee
    Person.find_by(email: Settings.assignments.default_assignee_email)
  end
end
