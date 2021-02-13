# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# encoding:  utf-8

require "spec_helper"

describe Event::RolesController, type: :controller do

  # always use fixtures with crud controller examples, otherwise request reuse might produce errors
  let(:test_entry) { event_roles(:top_leader) }

  let(:course) { test_entry.event }
  let(:group)  { course.groups.first }

  let(:new_entry_attrs) do
    {
      type: Event::Role::AssistantLeader.sti_name
    }
  end

  let(:create_entry_attrs) do
    {
      label: "Materialchef",
      type: Event::Role::AssistantLeader.sti_name,
      person_id: Fabricate(:person).id
    }
  end

  let(:test_entry_attrs) do
    {
      label: "Materialchef"
    }
  end

  def scope_params
     { group_id: group.id, event_id: course.id }
  end


  before { sign_in(people(:top_leader)) }

  # Override a few methods to match the actual behavior.
  class << self
    def it_should_redirect_to_show
      it do |example|
        if example.metadata[:action] == :create
          is_expected.to redirect_to edit_group_event_participation_path(group, course, entry.participation_id)
        else
          is_expected.to redirect_to group_event_participation_path(group, course, entry.participation_id)
        end
      end
    end

    def it_should_redirect_to_index
      it { is_expected.to redirect_to group_event_participations_path(group, course) }
    end

  end


  include_examples "crud controller", skip: [%w(index), %w(show), %w(new plain), %w(create html)]


  describe_action :get, :new do
    context ".html", format: :html do
      it "should raise exception if no type is given", perform_request: false do
        expect { perform_request }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe_action :post, :create do
    context ".html", format: :html do
      let(:params) { { model_identifier => create_entry_attrs } }
      it "creates answers on the go", perform_request: false do
        expect { perform_request }.to change { Event::Answer.count }.by(3)
      end

     context "with valid params" do
        it_should_redirect_to_show
        # it_should_set_attrs
        it_should_have_flash(:notice)

        it "should persist entry" do
          expect(entry).to be_persisted
          expect(entry).to be_kind_of(Event::Role::AssistantLeader)
          expect(entry.label).to eq(create_entry_attrs[:label])
          expect(entry.participation).to be_persisted
          expect(entry.participation.person_id).to eq(create_entry_attrs[:person_id])
        end
      end
    end
  end

  describe_action :delete, :destroy, id: true do
    context ".html", format: :html do
      it "should destroy participation for last role", perform_request: false do
        expect { perform_request }.to change { Event::Participation.count }.by(-1)
      end
    end
  end
end
