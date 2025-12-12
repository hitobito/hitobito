# frozen_string_literal: true

#
# == Schema Information
#
# Table name: table_displays
#
#  id                :integer          not null, primary key
#  selected          :text
#  table_model_class :string           not null
#  person_id         :integer          not null
#
# Indexes
#
#  index_table_displays_on_person_id_and_table_model_class  (person_id,table_model_class) UNIQUE
#
require "spec_helper"

describe TableDisplay do
  let(:leader) { people(:top_leader) }
  let(:group) { groups(:top_layer) }
  let(:event) { events(:top_event) }

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

  it "allows resetting selected columns" do
    subject = TableDisplay.for(leader, Person)
    subject.update!(selected: %w[gender])
    subject.update!(selected: [])
    expect(subject.selected).not_to be_present
  end

  it "rejects unregistered attributes" do
    TableDisplay.register_column(Person, TableDisplays::PublicColumn, [:first_name])

    person = people(:top_leader)

    subject.person_id = person.id
    subject.table_model_class = Person
    subject.selected = %w[name first_name id confirm]
    expect { subject.save! }.not_to raise_error
    expect(subject.active_columns([])).not_to include :name
    expect(subject.active_columns([])).to include :first_name
    expect(subject.active_columns([])).not_to include :id
    expect(subject.active_columns([])).not_to include :confirm
  end

  context :column_for do
    let(:member) { people(:bottom_member) }

    subject { TableDisplay.for(member, Person) }

    before do
      TableDisplay.register_column(Person, TestUpdateableColumn, :attr)
      subject.selected = %w[other_attr attr]
    end

    context "access checking" do
      it "does not return column for unregistered attribute" do
        expect(subject.column_for("other_attr")).to be_nil
      end

      it "yields if access check succeeds" do
        expect do |b|
          subject.column_for("attr").value_for(member, "attr", &b)
        end.to yield_with_args(member, "attr")
      end

      it "noops if access check fails" do
        expect { |b| subject.column_for("attr").value_for(leader, "attr", &b) }.not_to yield_control
      end
    end

    describe "table on column" do
      let(:table) { OpenStruct.new(template: OpenStruct.new(parent: group)) }

      it "is nil when no selected group is set" do
        expect(subject.column_for("attr").table).to be_nil
      end

      it "is returned as passed in" do
        expect(subject.column_for("attr", table: table).table).to eq table
      end

      it "is built dynamically according to UI usage when selected_group is set" do
        subject.selected_group = group
        expect(subject.column_for("attr", table: table).table).to eq table
      end
    end
  end

  context "participations" do
    let(:top_course) { events(:top_course) }
    let(:question) { event_questions(:top_ov) }

    subject { TableDisplay.for(leader, Event::Participation) }

    it "translates person columns for sort statements" do
      TableDisplay.register_column(Event::Participation, TableDisplays::PolymorphicPublicColumn,
        :"participant.birthday")
      subject.selected = %w[participant.birthday]
      expect(subject.sort_statements([])).to eq({
        "participant.birthday": {
          order: "CASE event_participations.participant_type WHEN 'Person' THEN people.birthday " \
            "WHEN 'Event::Guest' THEN event_guests.birthday END AS birthday_order_statement",
          order_alias: "birthday_order_statement"
        }
      })
    end

    it "builds custom sort statements for questions" do
      skip("disabled until sorting issue is fixed")
      TableDisplay.register_multi_column(Event::Participation,
        TableDisplays::Event::Participations::QuestionColumn)
      subject.selected = %W[event_question_1 event_question_#{question.id} event_question_2]
      statements = subject.sort_statements(top_course.participations)
      expect(statements).to have(1).item
      expect(statements[:"event_question_#{question.id}"])
        .to eq "event_questions.id = 768566425 ASC, TRIM(event_answers.answer)"
    end

    it "rejects unregistered person attributes" do
      TableDisplay.register_column(Event::Participation, TableDisplays::PublicColumn,
        [:"person.first_name"])

      person = people(:top_leader)

      subject.person_id = person.id
      subject.selected = %w[name person.id person.first_name]
      expect(subject.save).to eq true
      expect(subject.selected).not_to include "name"
      expect(subject.selected).not_to include "person.id"
      expect(subject.selected).to include "person.first_name"
    end
  end
end

class TestUpdateableColumn < TableDisplays::PublicColumn
  def required_permission(_attr)
    :update
  end

  def self.valid?(model_class, attrs)
    attrs.present? && model_class == Person
  end
end
