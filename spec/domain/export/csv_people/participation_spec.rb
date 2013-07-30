# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Export::CsvPeople::Participation do
  
  let(:person) { people(:top_leader) }
  let(:participation) { Fabricate(:event_participation, person: person, event: events(:top_course)) }

  subject { Export::CsvPeople::Participation.new(participation) }
  
  its([:first_name]) { should eq 'Top' }
  its([:roles]) { should be_blank }
  its([:additional_information]) { should be_blank }

  context "with additional information" do
    before { participation.update_attribute(:additional_information, 'foobar') }
    its([:additional_information]) { should eq 'foobar' }
  end

  context "with roles" do
    before do
      Fabricate(:event_role, participation: participation, type: 'Event::Role::Leader')
      Fabricate(:event_role, participation: participation, type: 'Event::Role::AssistantLeader')
    end
    its([:roles]) { should eq 'Hauptleitung, Leitung' }
  end

  context "with answers" do
    let(:question) { event_questions(:top_ov) }
    let(:answer)  { participation.answers.find_by_question_id(question.id) }
    before do
      participation.init_answers
      answer.update_attribute(:answer, question.choice_items.first)
      participation.reload
    end
    it "has answer for first question" do
      subject[:"question_#{question.id}"].should be_present
    end
  end
end
