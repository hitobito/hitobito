# encoding: UTF-8
require 'spec_helper'
describe Export::CsvPeople do

  let(:person) { people(:top_leader) }
  let(:participation) { Fabricate(:event_participation, person: person, event: events(:top_course)) }
  let(:simple_headers) { ["Vorname", "Nachname", "Übername", "Firmenname", "Firma", "E-Mail",
                          "Adresse", "PLZ", "Ort", "Land", "Geburtstag", "Rollen" ] }
  let(:full_headers) { ["Vorname", "Nachname", "Firmenname", "Übername", "Firma", "E-Mail", 
                        "Adresse", "PLZ", "Ort", "Land", "Geschlecht", "Geburtstag", 
                        "Zusätzliche Angaben", "Rollen"] }

  describe Export::CsvPeople do

    subject { csv }
    let(:list) { [person] }
    let(:data) { Export::CsvPeople.export_address(list) }
    let(:csv) { CSV.parse(data, headers: true, col_sep: Settings.csv.separator) }


    context "export" do
      its(:headers) { should == simple_headers }

      context "first row" do

        subject { csv[0] }

        its(['Vorname']) { should eq person.first_name }
        its(['Nachname']) { should eq person.last_name }
        its(['E-Mail']) { should eq person.email }
        its(['Ort']) { should eq person.town }
        its(['Rollen']) { should eq "Rolle TopGroup" }
        its(['Geschlecht']) { should be_blank }

        context "roles and phone number" do
          before do
            Fabricate(Group::BottomGroup::Member.name.to_s, group: groups(:bottom_group_one_one), person: person)
            person.phone_numbers.create(label: 'vater', number: 123)
          end

          its(['Telefonnummer Vater']) { should eq '123' }
          its(['Rollen']) { should eq 'Rolle Group 11, Rolle TopGroup' }
        end
      end
    end

    context "export_full" do
      its(:headers) { should == full_headers }
      let(:data) { Export::CsvPeople.export_full(list) }

      context "first row" do
        before do
          person.update_attribute(:gender, 'm')
          person.social_accounts << SocialAccount.new(label: 'skype', name: 'foobar')
          person.phone_numbers << PhoneNumber.new(label: 'vater', number: 123, public: false)
        end

        subject { csv[0] }

        its(['Rollen']) { should eq "Rolle TopGroup" }
        its(['Telefonnummer Vater']) { should eq '123' }
        its(['Skype']) { should eq 'foobar' }
        its(['Geschlecht']) { should eq 'm' }
      end
    end

    context "export_participations_address" do
      let(:list) { [participation] }
      let(:data) { Export::CsvPeople.export_participations_address(list) }

      its(:headers) { should == simple_headers }

      context "first row" do
        subject { csv[0] }

        its(['Vorname']) { should eq person.first_name }
        its(['Rollen']) { should be_blank }

        context "with roles" do
          before do
            Fabricate(:event_role, participation: participation, type: 'Event::Role::Leader')
            Fabricate(:event_role, participation: participation, type: 'Event::Role::AssistantLeader')
          end
          its(['Rollen']) { should eq 'Hauptleiter, Hilfsleiter' }
        end
      end
    end


    context "export_participations_full" do
      let(:list) { [participation] }
      let(:data) { Export::CsvPeople.export_participations_full(list) }

      its(:headers) { should == simple_headers }

      context "first row" do
        subject { csv[0] }

        its(['Vorname']) { should eq person.first_name }
        its(['Rollen']) { should be_blank }

        context "with additional information" do
          before { participation.update_attribute(:additional_information, 'foobar') }
          its(['Bemerkungen (Allgemeines, Gesundheitsinformationen, Allergien, usw.)']) { should eq 'foobar' }
        end

        context "with roles" do
          before do
            Fabricate(:event_role, participation: participation, type: 'Event::Role::Leader')
            Fabricate(:event_role, participation: participation, type: 'Event::Role::AssistantLeader')
          end
          its(['Rollen']) { should eq 'Hauptleiter, Hilfsleiter' }
        end

        context "with answers" do
          let(:first_question) { event_questions(:top_ov) }
          let(:first_answer)  { participation.answers.find_by_question_id(first_question.id) }

          let(:second_question) { event_questions(:top_vegi) }
          let(:second_answer)  { participation.answers.find_by_question_id(second_question.id) }

          before do
            participation.init_answers
            first_answer.update_attribute(:answer, first_question.choice_items.first)
            second_answer.update_attribute(:answer, second_question.choice_items.first)
            participation.reload
          end

          it "has answer for first question" do
            subject["#{first_question.question}"].should eq 'GA'
            subject["#{second_question.question}"].should eq 'ja'
          end
        end
      end
    end
  end


end
