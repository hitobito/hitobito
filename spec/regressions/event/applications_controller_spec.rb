# encoding:  utf-8

require 'spec_helper'

describe Event::ApplicationsController, type: :controller do

  let(:course) do
    course = Fabricate(:course, group: groups(:top_layer))
    course.questions << Fabricate(:event_question, event: course)
    course.questions << Fabricate(:event_question, event: course)
    course
  end
  
  let(:test_entry) { Fabricate(:event_application, priority_1: course) }
  
  let(:test_entry_attrs) do
    { 
      participation_attributes: {
        answers_attributes: [
          {answer: 'ja',   question_id: course.questions[0].id},
          {answer: 'nein', question_id: course.questions[1].id}
        ],
        additional_information: 'blalbalbalsbla'
      }, 
      priority_2_id: nil
    }
  end

  before { sign_in(people(:top_leader)) } 
  before { test_entry } # load test entry before tests to avoid some bugs
  
  let(:scope_params) { {event_id: test_entry.priority_1_id} }

  include_examples 'crud controller', skip: [%w(index), %w(destroy)]

end
