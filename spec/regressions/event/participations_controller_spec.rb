# encoding:  utf-8

require 'spec_helper'

describe Event::ParticipationsController, type: :controller do

  let(:course) do
    course = Fabricate(:course, group: groups(:top_layer))
    course.questions << Fabricate(:event_question, event: course)
    course.questions << Fabricate(:event_question, event: course)
    course
  end
  
  let(:test_entry) { Fabricate(:event_participation, event: course) }
  
  let(:test_entry_attrs) do
    { 
      additional_information: 'blalbalbalsbla',
      answers_attributes: [
        {answer: 'ja',   question_id: course.questions[0].id},
        {answer: 'nein', question_id: course.questions[1].id}
      ],
      application_attributes: { priority_2_id: nil }
    }
  end

  before { sign_in(people(:top_leader)) } 
  before { Fabricate(Event::Role::Leader.name.to_sym, participation: test_entry) }
  
  let(:scope_params) { {event_id: test_entry.event_id} }

  include_examples 'crud controller', skip: [%w(destroy)]

end
