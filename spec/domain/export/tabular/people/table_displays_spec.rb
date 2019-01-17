require 'spec_helper'

describe Export::Tabular::People::TableDisplays do

  let(:person) { people(:top_leader) }

  context 'people' do
    let(:people_list)   { Export::Tabular::People::TableDisplays.new(list, table_display) }
    let(:table_display) { TableDisplay::People.new }
    let(:list)          { [person] }

    subject { people_list }

    its(:attributes) do
      should == [:first_name, :last_name, :nickname, :company_name, :company, :email, :address,
                :zip_code, :town, :country, :gender, :birthday, :layer_group, :roles]
    end

    it 'includes additional attributes if configured' do
      table_display.selected = %w(gender)
      expect(people_list.labels.last).to eq 'Geschlecht'
      expect(people_list.attributes.last).to eq 'gender'
      expect(people_list.data_rows.first.last).to eq 'unbekannt'
    end

    it 'does not include the same attriubte twice' do
      table_display.selected = %w(first_name)
      expect(people_list.attributes.grep(/first_name/).count).to eq 1
    end
  end


  context 'participations' do
    let(:people_list)   { Export::Tabular::People::TableDisplays.new(list, table_display) }
    let(:table_display) { TableDisplay::Participations.new }
    let(:participation) { event_participations(:top) }
    let(:list)          { [participation] }
    let(:question)      { event_questions(:top_ov) }

    subject { people_list }

    its(:attributes) do
      should == [:first_name, :last_name, :nickname, :company_name, :company, :email, :address,
                :zip_code, :town, :country, :gender, :birthday, :layer_group, :roles]
    end

    it 'includes additional person attributes if configured' do
      table_display.selected = %w(person.gender)
      expect(people_list.labels.last).to eq 'Geschlecht'
      expect(people_list.attributes.last).to eq 'person.gender'
      expect(people_list.data_rows.first.last).to eq 'unbekannt'
    end

    it 'includes configured questions that exist on this event' do
      participation.answers.create!(question: question, answer: 'GA')
      table_display.selected = %W(event_question_1 event_question_#{question.id} event_question_2)
      expect(people_list.labels.last).to eq 'GA oder Halbtax?'
      expect(people_list.attributes.last).to eq "event_question_#{question.id}"
      expect(people_list.data_rows.first.last).to eq 'GA'
    end
  end
end
