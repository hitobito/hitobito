# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "question_templates/_table.html.haml" do
  let(:person) { people(:top_leader) }
  let(:group) { groups(:top_layer) }
  let(:template) { event_question_templates(:ga_template) }
  let(:entries) { Event::QuestionTemplateDecorator.decorate_collection([template]) }
  let(:dom) { Capybara::Node::Simple.new(raw(rendered)) }

  before do
    allow(view).to receive_messages(current_user: person, group: group)
    allow(controller).to receive_messages(current_user: person)
    controller.request.path_parameters.merge!(group_id: group.id, action: "index")
  end

  context "when template is editable" do
    before { render partial: "question_templates/table", locals: {entries: entries} }

    it "renders edit link" do
      expect(dom).to have_link(href: edit_group_question_template_path(group, template))
    end

    it "renders destroy link" do
      expect(dom).to have_link(href: group_question_template_path(group, template))
    end
  end

  context "when template is not editable" do
    before do
      allow(Event::Question::Default).to receive(:template_editable).and_return(false)
      render partial: "question_templates/table", locals: {entries: entries}
    end

    it "does not render edit link" do
      expect(dom).to have_no_link(href: edit_group_question_template_path(group, template))
    end

    it "does not render destroy link" do
      expect(dom).to have_no_link(href: group_question_template_path(group, template))
    end
  end
end
