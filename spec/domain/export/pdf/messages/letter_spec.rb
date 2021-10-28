# frozen_string_literal: true

#  Copyright (c) 2020-2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Export::Pdf::Messages::Letter do

  let(:letter) do
    Message::Letter.create!(mailing_list: list,
                            body: messages(:letter).body,
                            subject: "Information")
  end
  let(:options) { {} }
  let(:layer) { groups(:bottom_layer_one) }
  let(:group) { groups(:bottom_group_one_one) }
  let(:list) { Fabricate(:mailing_list, group: group) }
  let(:analyzer) { PDF::Inspector::Text.analyze(subject.render) }

  subject { described_class.new(letter, options) }

  before do
    people(:top_leader).update!(address: 'Funkystreet 42', zip_code: '4242')
  end

  it "sanitizes filename" do
    letter.subject = "Liebe Mitglieder"
    expect(subject.filename).to eq "liebe_mitglieder.pdf"
  end

  it "prepends arguments passed" do
    letter.subject = "Liebe Mitglieder"
    expect(subject.filename(:preview)).to eq "preview-liebe_mitglieder.pdf"
  end

  context "text" do

    context "single recipient" do

      before do
        people(:top_leader).update!(address: 'Funkystreet 42', zip_code: '4242')
        Subscription.create!(mailing_list: list,
                             subscriber: group,
                             role_types: [Group::BottomGroup::Member])
        Fabricate(Group::BottomGroup::Member.name, group: group, person: people(:bottom_member))
        Messages::LetterDispatch.new(letter).run
      end

      it "renders text at positions without sender address" do
        expect(text_with_position).to match_array [
          [71, 654, "Bottom Member"],
          [71, 644, "Greatstreet 345"],
          [71, 633, "3456 Greattown"],
          [71, 531, "Information"],
          [71, 502, "Hallo"],
          [71, 481, "Wir laden "],
          [111, 481, "dich"],
          [130, 481, " ein! "],
          [71, 460, "Bis bald"]
        ]
      end

      it "renders text at positions with group sender address" do
        letter.update!(pp_post: 'Group 11, Lakeview 42, 4242 Wanaka')

        expect(text_with_position).to match_array [
          [71, 687, "Group 11, Lakeview 42, 4242 Wanaka"],
          [71, 654, "Bottom Member"],
          [71, 644, "Greatstreet 345"],
          [71, 633, "3456 Greattown"],
          [71, 531, "Information"],
          [71, 502, "Hallo"],
          [71, 481, "Wir laden "],
          [111, 481, "dich"],
          [130, 481, " ein! "],
          [71, 460, "Bis bald"]
        ]
      end

      it "renders example letter" do
        options[:debug] = true
        image = fixture_file_upload("images/logo.png")
        GroupSetting.create!(target: groups(:top_group), var: :messages_letter, picture: image).id
        letter.update!(group: groups(:top_group))
        layer.update!(address: "Lakeview 42", zip_code: "4242", town: "Bern")
        IO.binwrite("/tmp/file.pdf", subject.render)
      end
    end

    context "stamping" do
      let(:stamps) { subject.pdf.instance_variable_get("@stamp_dictionary_registry") }

      before do
        Subscription.create!(mailing_list: list,
                             subscriber: group,
                             role_types: [Group::BottomGroup::Member])
        Fabricate(Group::BottomGroup::Member.name, group: group, person: people(:bottom_member))
        Fabricate(Group::BottomGroup::Member.name, group: group, person: people(:top_leader))
        Messages::LetterDispatch.new(letter).run
      end


      it "renders addresses and content" do
        expect(text_with_position).to eq [
          [71, 654, "Bottom Member"],
          [71, 644, "Greatstreet 345"],
          [71, 633, "3456 Greattown"],
          [71, 531, "Information"],
          [71, 502, "Hallo"],
          [71, 481, "Wir laden "],
          [111, 481, "dich"],
          [130, 481, " ein! "],
          [71, 460, "Bis bald"],
          [71, 654, "Top Leader"],
          [71, 644, "Funkystreet 42"],
          [71, 633, "4242 Supertown"],
          [71, 531, "Information"],
          [71, 502, "Hallo"],
          [71, 481, "Wir laden "],
          [111, 481, "dich"],
          [130, 481, " ein! "],
          [71, 460, "Bis bald"]
        ]
        expect(stamps).to be_nil
      end

      it "renders only addresses has stamps" do
        options[:stamped] = true
        expect(text_with_position).to eq [
          [71, 654, "Bottom Member"],
          [71, 644, "Greatstreet 345"],
          [71, 633, "3456 Greattown"],
          [71, 654, "Top Leader"],
          [71, 644, "Funkystreet 42"],
          [71, 633, "4242 Supertown"],
        ]
        expect(stamps.keys).to eq [:render_logo_right, :render_shipping_info, :render_subject, :render_content]
      end

      it "falls back to normal rendering if stamping fails because content is to big" do
        letter.body = Faker::Lorem.paragraphs(number: 100)
        options[:stamped] = true
        expect(text_with_position).to be_present
        expect(stamps).to be_nil
      end
    end
  end

  context 'household addresses' do

    let(:housemate1) { Fabricate(:person_with_address, first_name: 'Anton', last_name: 'Abraham') }
    let(:housemate2) { Fabricate(:person_with_address, first_name: 'Zora', last_name: 'Zaugg') }
    let(:other_housemate) { Fabricate(:person_with_address, first_name: 'Altra', last_name: 'Mates') }

    before do
      Subscription.create!(mailing_list: list,
                           subscriber: group,
                           role_types: [Group::BottomGroup::Member])
      Fabricate(Group::BottomGroup::Member.name, group: group, person: housemate1)
      Fabricate(Group::BottomGroup::Member.name, group: group, person: housemate2)
      Fabricate(Group::BottomGroup::Member.name, group: group, person: people(:bottom_member))
      Fabricate(Group::BottomGroup::Member.name, group: group, person: people(:top_leader))

      create_household(housemate1, housemate2)
      create_household(other_housemate, people(:top_leader))

      letter.update!(send_to_households: true)

      Messages::LetterDispatch.new(letter).run
    end

    it 'creates only one letter per household' do
      expect(text_with_position).to eq [
        [71, 654, "Anton Abraham, Zora Zaugg"],
        [71, 644, housemate1.address],
        [71, 633, "#{housemate1.zip_code} #{housemate1.town}"],
        [71, 623, "DE"],
        [71, 531, "Information"],
        [71, 502, "Hallo"],
        [71, 481, "Wir laden "],
        [111, 481, "dich"],
        [130, 481, " ein! "],
        [71, 460, "Bis bald"],
        [71, 654, "Bottom Member"],
        [71, 644, "Greatstreet 345"],
        [71, 633, "3456 Greattown"],
        [71, 531, "Information"],
        [71, 502, "Hallo"],
        [71, 481, "Wir laden "],
        [111, 481, "dich"],
        [130, 481, " ein! "],
        [71, 460, "Bis bald"],
        [71, 654, "Top Leader"],
        [71, 644, "Funkystreet 42"],
        [71, 633, "4242 Supertown"],
        [71, 531, "Information"],
        [71, 502, "Hallo"],
        [71, 481, "Wir laden "],
        [111, 481, "dich"],
        [130, 481, " ein! "],
        [71, 460, "Bis bald"]]
    end

    it 'adds all household peoples names to address and sorts them alphabetically' do
      Fabricate(Group::BottomGroup::Member.name, group: group, person: other_housemate)
      create_household(housemate1, other_housemate)
      create_household(housemate1, people(:bottom_member))

      letter.message_recipients.destroy_all
      Messages::LetterDispatch.new(letter).run

      expect(text_with_position).to match_array [
        [71, 654, "Anton Abraham, Top Leader, Altra Mates, Bottom"],
        [71, 644, "Member, Zora Zaugg"],
        [71, 633, "Greatstreet 345"],
        [71, 623, "3456 Greattown"],
        [71, 531, "Information"],
        [71, 502, "Hallo"],
        [71, 481, "Wir laden "],
        [111, 481, "dich"],
        [130, 481, " ein! "],
        [71, 460, "Bis bald"]]
    end

  end

  context 'preview' do
    let(:analyzer) { PDF::Inspector::Text.analyze(subject.render_preview) }

    before do
      Subscription.create!(mailing_list: list,
                           subscriber: group,
                           role_types: [Group::BottomGroup::Member])
      Fabricate(Group::BottomGroup::Member.name, group: group, person: people(:bottom_member))
    end

    it 'creates preview without persisted message recipients' do
      expect(text_with_position).to match_array [
        [71, 654, "Bottom Member"],
        [71, 644, "Greatstreet 345"],
        [71, 633, "3456 Greattown"],
        [71, 531, "Information"],
        [71, 502, "Hallo"],
        [71, 481, "Wir laden "],
        [111, 481, "dich"],
        [130, 481, " ein! "],
        [71, 460, "Bis bald"]
      ]
      expect(letter.message_recipients.reload.count).to eq(0)
    end

    context 'household addresses' do

      let(:housemate1) { Fabricate(:person_with_address, first_name: 'Anton', last_name: 'Abraham') }
      let(:housemate2) { Fabricate(:person_with_address, first_name: 'Zora', last_name: 'Zaugg') }
      let(:housemate3) { Fabricate(:person_with_address, first_name: 'Bettina', last_name: 'Büttel') }
      let(:housemate4) { Fabricate(:person_with_address, first_name: 'Carlo', last_name: 'Colorado') }
      let(:other_housemate) { Fabricate(:person_with_address, first_name: 'Altra', last_name: 'Mates') }
      let(:top_leader) { people(:top_leader) }
      let(:bottom_member) { people(:bottom_member) }
      let(:single_person) { Fabricate(:person_with_address, first_name: 'Dominik', last_name: 'Dachs') }

      before do
        Subscription.create!(mailing_list: list,
                             subscriber: group,
                             role_types: [Group::BottomGroup::Member])
        Fabricate(Group::BottomGroup::Member.name, group: group, person: housemate1)
        Fabricate(Group::BottomGroup::Member.name, group: group, person: housemate2)
        Fabricate(Group::BottomGroup::Member.name, group: group, person: housemate3)
        Fabricate(Group::BottomGroup::Member.name, group: group, person: housemate4)
        Fabricate(Group::BottomGroup::Member.name, group: group, person: top_leader)
        Fabricate(Group::BottomGroup::Member.name, group: group, person: bottom_member)
        Fabricate(Group::BottomGroup::Member.name, group: group, person: single_person)

        create_household(housemate1, housemate2)
        create_household(housemate3, housemate4)
        create_household(other_housemate, people(:top_leader))

        letter.update!(send_to_households: true, body: 'Hallo', subject: nil)
      end

      it 'creates preview with half normal half household recipients' do
        expect(text_with_position).to match_array [
          [71, 654, "Anton Abraham, Zora Zaugg"],
          [71, 644, housemate1.address],
          [71, 633, "#{housemate1.zip_code} #{housemate1.town}"],
          [71, 623, "DE"],
          [71, 502, "Hallo"],
          [71, 654, "Bettina Büttel, Carlo Colorado"],
          [71, 644, housemate3.address],
          [71, 633, "#{housemate3.zip_code} #{housemate3.town}"],
          [71, 623, "DE"],
          [71, 502, "Hallo"],
          [71, 654, "Bottom Member"],
          [71, 644, bottom_member.address],
          [71, 633, "#{bottom_member.zip_code} #{bottom_member.town}"],
          [71, 502, "Hallo"],
          [71, 654, "Dominik Dachs"],
          [71, 644, single_person.address],
          [71, 633, "#{single_person.zip_code} #{single_person.town}"],
          [71, 623, "DE"],
          [71, 502, "Hallo"],
        ]
      end

      it 'includes all housemates, even when the underlying people scope is limited for previewing' do
        create_household(housemate1, housemate3)
        create_household(housemate1, housemate4)

        expect(text_with_position).to match_array [
          [71, 654, "Anton Abraham, Bettina Büttel, Carlo Colorado,"],
          [71, 644, "Zora Zaugg"],
          [71, 633, housemate1.address],
          [71, 623, "#{housemate1.zip_code} #{housemate1.town}"],
          [71, 612, "DE"],
          [71, 502, "Hallo"],
          [71, 654, "Bottom Member"],
          [71, 644, bottom_member.address],
          [71, 633, "#{bottom_member.zip_code} #{bottom_member.town}"],
          [71, 502, "Hallo"],
          [71, 654, "Top Leader"],
          [71, 644, top_leader.address],
          [71, 633, "#{top_leader.zip_code} #{top_leader.town}"],
          [71, 502, "Hallo"],
          [71, 654, "Dominik Dachs"],
          [71, 644, single_person.address],
          [71, 633, "#{single_person.zip_code} #{single_person.town}"],
          [71, 623, "DE"],
          [71, 502, "Hallo"],
        ]
      end
    end
  end

  private

  def text_with_position
    analyzer.positions.each_with_index.collect do |p, i|
      p.collect(&:round) + [analyzer.show_text[i]]
    end
  end

  def create_household(person1, person2)
    fake_ability = instance_double('aby', cannot?: false)
    household = Person::Household.new(person1, fake_ability, person2, people(:top_leader))
    household.assign
    household.save
  end
end
