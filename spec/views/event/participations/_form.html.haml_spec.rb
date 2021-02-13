# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "event/participations/_form.html.haml" do

  let(:participant) { people(:top_leader) }
  let(:participation) { Fabricate(:event_participation, person: participant, event: event) }
  let(:user) { participant }
  let(:event) { events(:top_event) }
  let(:group) { event.groups.first }
  let(:question) { event_questions(:top_ov) }
  let(:dom) { Capybara::Node::Simple.new(rendered) }
  let(:answer_text) { nil }

  before do
    question.update_attribute(:multiple_choices, true)
    event.questions << question
    answer = participation.answers.detect { |a| a.question_id == question.id }
    answer.answer = answer_text

    decorated = Event::ParticipationDecorator.new(participation)

    allow(view).to receive_messages(path_args: [group, event, decorated])
    allow(view).to receive_messages(entry: decorated)
    allow(view).to receive_messages(model_class: Event::Participation)
    allow(view).to receive(:current_user) { user }

    allow(controller).to receive_messages(current_user: user)
    assign(:event, event.decorate)
    assign(:group, group)
    assign(:answers, participation.answers)
  end

  context "course" do
    let(:event) { events(:top_course) }


    context "kind" do
      it "shows application conditions and general information when set" do
        event.kind.update!(application_conditions: "some application conditions",
                           general_information: "some general information")
        render
        is_expected.not_to have_content "some general informations"
        is_expected.not_to have_content "some application conditions"
      end
    end
  end

  context "checkboxes" do
    let(:ga) { dom.find_field("GA") }
    let(:halbtax) { dom.find_field("Halbtax") }

    context "unchecked" do

      shared_examples "unchecked_multichoice_checkbox" do
        before { render }

        it { is_expected.not_to be_checked }
        its([:name]) { should eq "event_participation[answers_attributes][0][answer][]" }
        its([:type]) { should eq "checkbox" }
        its([:value]) { should eq value }
      end

      describe "Choice GA" do
        subject { ga }
        let(:value) { "1" }

        it_behaves_like "unchecked_multichoice_checkbox"
      end

      describe "Choice Halbtax" do
        subject { halbtax }
        let(:value) { "2" }

        it_behaves_like "unchecked_multichoice_checkbox"
      end
    end

    describe "Halbtax checked" do
      let(:answer_text) { "Halbtax" }
      before { render }

      it { expect(ga).not_to be_checked }
      it { expect(halbtax).to be_checked }
    end


    describe "GA, Halbtax checked" do
      let(:answer_text) { "GA, Halbtax" }
      before { render }

      it { expect(ga).to be_checked }
      it { expect(halbtax).to be_checked }
    end
  end

end
