#  Copyright (c) 2012-2018, Schweizer Blasmusikverband. This file is part of
#  hitobito_sbv and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Export::Tabular::People::TableDisplays do

  let(:person) { people(:top_leader) }
  let!(:registered_columns) { TableDisplay.table_display_columns.clone }
  let!(:registered_multi_columns) { TableDisplay.multi_columns.clone }

  before do
    TableDisplay.table_display_columns = {}
    TableDisplay.multi_columns = {}
  end

  after do
    TableDisplay.table_display_columns = registered_columns
    TableDisplay.multi_columns = registered_multi_columns
  end

  context 'people' do
    let(:people_list)   { Export::Tabular::People::TableDisplays.new(list, table_display) }
    let(:table_display) { TableDisplay.new(person: person, table_model_class: 'Person') }
    let(:list) do
      Person.where(id: person.id)
          .includes(:phone_numbers, :additional_emails, :primary_group)
          .references(:phone_numbers, :additional_emails, :primary_group)
    end

    before { TableDisplay.register_column(Person, TestUpdateableColumn, [:additional_information]) }

    subject { people_list }

    its(:attributes) do
      should == [:first_name, :last_name, :nickname, :company_name, :company, :email, :address,
                 :zip_code, :town, :country, :gender, :birthday, :layer_group, :roles, :tags]
    end

    it 'does not allow accessing unregistered columns' do
      table_display.selected = %i(years)
      expect(people_list.labels.last).to eq 'Tags'
      expect(people_list.attributes.last).to eq :tags
      expect(people_list.attributes.grep(/years/).count).to eq 0
    end

    it 'includes additional information if configured' do
      table_display.selected = %i(additional_information)
      expect(people_list.labels.last).to eq 'Zusätzliche Angaben'
      expect(people_list.attributes.last).to eq :additional_information
      expect(people_list.data_rows.first.last).to eq 'bla bla'
    end

    it 'does not include additional information if no access' do
      table_display.person = people(:bottom_member)
      table_display.selected = %i(additional_information)
      expect(people_list.labels.last).to eq 'Zusätzliche Angaben'
      expect(people_list.attributes.last).to eq :additional_information
      expect(people_list.data_rows.first.last).to be_nil
    end

    it 'does not include the same attribute twice' do
      table_display.selected = %i(first_name)
      expect(people_list.attributes.grep(/first_name/).count).to eq 1
    end

    it 'does include dynamic attributes' do
      person.phone_numbers.create!(label: 'foobar', number: '0790000000')
      expect(people_list.labels.last).to eq 'Telefonnummer foobar'
      expect(people_list.data_rows.first.last).to eq '+41 79 000 00 00'
    end

    it 'does not fail when dynamic attributes include a .' do
      person.phone_numbers.create!(label: 'foo.bar', number: '0790000000')
      expect(people_list.labels.last).to eq 'Telefonnummer foo.bar'
      expect(people_list.data_rows.first.last).to eq '+41 79 000 00 00'
    end

    context :with_limited_select do
      let(:list) do
        Person.where(id: person.id)
            .select('email', 'primary_group_id')
            .includes(:phone_numbers, :additional_emails, :primary_group)
            .references(:phone_numbers, :additional_emails, :primary_group)
      end

      it 'does not fail' do
        table_display.selected = %i(additional_information)
        expect { people_list.data_rows.collect(&:presence) }.not_to raise_error
        expect(people_list.data_rows.collect(&:presence).compact.size).to eq 1
      end
    end

  end

  context 'participations' do
    let(:people_list)   { Export::Tabular::Event::Participations::TableDisplays.new(list, table_display) }
    let(:table_display) { TableDisplay.new(person: person, table_model_class: 'Event::Participation') }
    let(:participation) { event_participations(:top) }
    let(:person)        { participation.person }
    let(:list) do
      Event::Participation.where(id: participation.id)
          .includes(person: [ :phone_numbers, :additional_emails, :primary_group ])
          .references(person: [ :phone_numbers, :additional_emails, :primary_group ])
    end
    let(:question)      { event_questions(:top_ov) }
    let(:top_course)    { participation.event }

    subject { people_list }

    before do
      TableDisplay.register_column(Event::Participation,
                                   TableDisplays::PublicColumn,
                                   %i(person.additional_information))
      TableDisplay.register_multi_column(Event::Participation,
                                         TableDisplays::Event::Participations::QuestionColumn)
    end

    its(:attributes) do
      should == [:first_name, :last_name, :nickname, :company_name, :company, :email, :address,
                :zip_code, :town, :country, :gender, :birthday, :layer_group, :roles, :tags]
    end

    it 'includes additional person attributes if configured' do
      table_display.selected = %i(person.additional_information)
      person.update!(additional_information: 'bla bla')
      expect(people_list.labels.last).to eq 'Zusätzliche Angaben'
      expect(people_list.attributes.last).to eq :'person.additional_information'
      expect(people_list.data_rows.first.last).to eq 'bla bla'
    end

    it 'includes configured questions that exist on this event' do
      participation.answers.create!(question: question, answer: 'GA')
      table_display.selected = [:event_question_1, :"event_question_#{question.id}", :event_question_2]
      expect(people_list.labels.last).to eq 'GA oder Halbtax?'
      expect(people_list.attributes.last.to_s).to eq "event_question_#{question.id}"
      expect(people_list.data_rows.first.last).to eq 'GA'
    end

    it 'does not include the same attribute twice' do
      table_display.selected = %i(person.gender)
      expect(people_list.attributes.grep(/gender/).count).to eq 1
    end

    it 'does include dynamic attributes' do
      person.phone_numbers.create!(label: 'foobar', number: '0790000000')
      expect(people_list.labels.last).to eq 'Telefonnummer foobar'
      expect(people_list.data_rows.first.last).to eq '+41 79 000 00 00'
    end

    it 'does not fail when dynamic attributes include a .' do
      person.phone_numbers.create!(label: 'foo.bar', number: '0790000000')
      expect(people_list.labels.last).to eq 'Telefonnummer foo.bar'
      expect(people_list.data_rows.first.last).to eq '+41 79 000 00 00'
    end

    context :with_permission_check do
      before do
        TableDisplay.register_column(Event::Participation,
                                     TableDisplays::ShowFullColumn,
                                     %i(person.additional_information))
      end

      context :event_leader do
        let(:person) { Fabricate(Event::Role::Leader.sti_name, participation: Fabricate(:event_participation, event: top_course)).person  }

        it 'does include value of configured questions' do
          participation.answers.create!(question: question, answer: 'GA')
          table_display.selected = [:event_question_1, :"event_question_#{question.id}", :event_question_2]
          expect(people_list.data_rows.first.last).to eq 'GA'
        end

        it 'does not include value of protected attr' do
          table_display.selected = %i(person.additional_information)
          person.update!(additional_information: 'bla bla')
          expect(people_list.labels.last).to eq 'Zusätzliche Angaben'
          expect(people_list.attributes.last).to eq :'person.additional_information'
          expect(people_list.data_rows.first.last).to be_blank
        end
      end

      context :event_participant do
        let(:person) { Fabricate(Event::Role::Participant.sti_name, participation: Fabricate(:event_participation, event: top_course)).person }

        it 'does not include value of configured questions' do
          participation.answers.create!(question: question, answer: 'GA')
          table_display.selected = [:event_question_1, :"event_question_#{question.id}", :event_question_2]
          expect(people_list.data_rows.first.last).to be_blank
        end
      end
    end
  end
end

class TestUpdateableColumn < TableDisplays::PublicColumn
  def required_permission(attr)
    :update
  end
end
