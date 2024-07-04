# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

require "spec_helper"

describe "events/_form.html.haml" do
  let(:user) { people(:top_leader) }
  let(:event) { events(:top_event) }
  let(:group) { event.groups.first }
  let(:dom) { Capybara::Node::Simple.new(rendered) }

  before do
    allow(view).to receive_messages(path_args: [group, event])
    allow(view).to receive_messages(entry: event.decorate)
    allow(view).to receive_messages(current_user: user, model_class: event.class)
    allow(controller).to receive_messages(current_user: user)
    assign(:kinds, [])
    assign(:event, event)
    assign(:group, group)
  end

  context "course" do
    let(:event) { events(:top_course) }

    [:hidden_contact_attrs, :required_contact_attrs].each do |attr|
      it "renders Kontaktangaben tab when #{attr} is used" do
        allow(Event::Course).to receive(:used_attributes).and_return([attr])
        render
        expect(dom).to have_link "Kontaktangaben"
      end
    end
  end
end
