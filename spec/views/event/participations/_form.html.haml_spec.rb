# encoding: utf-8
require 'spec_helper'

describe "event/participations/_form.html.haml" do

  let(:participant) { people(:top_leader )}
  let(:participation) { Fabricate(:event_participation, person: participant, event: event) }
  let(:user) { participant }
  let(:event) { events(:top_event) }
  let(:group) { event.groups.first}
  let(:question) { event_questions(:top_ov) }
  let(:dom) { Capybara::Node::Simple.new(rendered) }

  before do
    question.update_attribute(:multiple_choices, true)
    event.questions << question
    answer = participation.answers.build
    answer.question = question
    answer.answer = "Halbtax"

    decorated = Event::ParticipationDecorator.new(participation)

    view.stub(path_args: [group, event, decorated])
    view.stub(entry: decorated)
    view.stub(model_class: Event::Participation)
    view.stub(:current_user) {user}

    controller.stub(current_user: user)
    assign(:event, event)
    assign(:group, group)
   
    render
  end

  it "supports checkboxes for answers" do
    dom.find_field('GA').should_not be_checked
    dom.find_field('Halbtax').should be_checked

    field = dom.find_field('Halbtax')

    field[:type].should eq 'checkbox'
    field[:name].should eq 'event_participation[answers_attributes][0][answer][]'
  end
  
end
