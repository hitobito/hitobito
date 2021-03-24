# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe AssignmentsController do
  let(:nesting)    { { group_id: bottom_member.primary_group.id, person_id: bottom_member.id } }
  let(:bottom_member) { people(:bottom_member) }
  let(:top_leader) { people(:top_leader) }
  let(:assignment) { assignments(:printing) }
  let(:different_member) do
    bottom_member.clone
    bottom_member.save!
    bottom_member
  end

  before { sign_in(top_leader) }

  context 'GET#show' do
    it 'does not update read_at if not assignee' do
      expect(assignment.read_at).to be_nil
      get :show, params: nesting.merge(id: assignment.id)

      expect(assignment.read_at).to be_nil
    end

    it 'updates read_at if assignee' do
      assignment.attachment.assignments = [assignment]

      sign_in(bottom_member)

      expect(assignment.read_at).to be_nil
      get :show, params: nesting.merge(id: assignment.id)

      assignment.reload
      expect(assignment.read_at).to_not be_nil
    end

    it 'can not show assignment if attachment not readable' do
      sign_in(different_member)

      expect do
        get :show, params: nesting.merge(id: assignment.id)
      end.to raise_error(CanCan::AccessDenied)
    end
  end

  context 'GET#new' do
    it 'assigns default_assignee' do
      assignments_settings = double
      expect(assignments_settings).to receive(:default_assignee_email).and_return(bottom_member.email)
      Settings.assignments = assignments_settings

      assignment_double = double
      expect_any_instance_of(AssignmentsController).to receive(:build_entry).and_return(assignment_double)
      expect(assignment_double).to receive(:attachment).and_return(assignment)

      expect(assignment_double).to receive(:class).and_return(Assignment).at_least(:once)
      expect(assignment_double).to receive(:person=).with(bottom_member)

      get :new
    end

    it 'can not new if attachment not writable' do
      sign_in(different_member)

      expect do
        get :new, params: { assignment: { attachment_id: assignment.attachment.id } }
      end.to raise_error(CanCan::AccessDenied)
    end
  end

  context 'POST#create' do
    it 'creates new assignment and assigns creator_id' do
      expect do
        post :create, params: {
          assignment: {
            title: 'test title',
            description: 'test description',
            attachment_id: messages(:letter).id,
            person_id: bottom_member.id
          }
        }
      end.to change { Assignment.count }.by(1)

      created = Assignment.find_by(title: 'test title')

      expect(created.creator).to eq(top_leader)
    end

    it 'enqueues notification mailer job' do
      expect(Assignment::SendNotificationJob).to receive(:new).and_call_original

      expect do
        post :create, params: {
          assignment: {
            title: 'test title',
            description: 'test description',
            attachment_id: messages(:letter).id,
            person_id: bottom_member.id
          }
        }
      end.to change { Delayed::Job.count }.by(2)
    end

    it 'enqueues message dispatch job of assignment' do
      expect(Messages::DispatchJob).to receive(:new).and_call_original

      expect do
        post :create, params: {
          assignment: {
            title: 'test title',
            description: 'test description',
            attachment_id: messages(:letter).id,
            person_id: bottom_member.id
          }
        }
      end.to change { Delayed::Job.count }.by(2)
    end

    it 'can not create if attachment not writeable' do
      sign_in(different_member)

      expect do
        post :create, params: {
          assignment: {
            title: 'test title',
            description: 'test description',
            attachment_id: messages(:letter).id,
            person_id: bottom_member.id
          }
        }
      end.to raise_error(CanCan::AccessDenied)
    end
  end
end
