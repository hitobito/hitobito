# frozen_string_literal: true

#  Copyright (c) 2020-2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

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

    let(:analyzer) { PDF::Inspector::Text.analyze(subject.render) }

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
          [71, 687, "Bottom Member"],
          [71, 676, "Greatstreet 345"],
          [71, 666, "3456 Greattown"],
          [71, 531, "Information"],
          [71, 502, "Hallo"],
          [71, 481, "Wir laden "],
          [111, 481, "dich"],
          [130, 481, " ein! "],
          [71, 460, "Bis bald"]
        ]
      end

      it "renders text at positions with group sender address" do
        letter.update!(heading: true)
        group_contact = Fabricate(Group::BottomGroup::Member.name, group: group).person
        group_contact.update!(address: 'Lakeview 42', zip_code: '4242', town: 'Wanaka')
        group.update!(contact: group_contact)

        expect(text_with_position).to match_array [
          [71, 765, "Group 11"],
          [71, 754, "Lakeview 42"],
          [71, 744, "4242 Wanaka"],
          [71, 687, "Bottom Member"],
          [71, 676, "Greatstreet 345"],
          [71, 666, "3456 Greattown"],
          [71, 531, "Information"],
          [71, 502, "Hallo"],
          [71, 481, "Wir laden "],
          [111, 481, "dich"],
          [130, 481, " ein! "],
          [71, 460, "Bis bald"]
        ]
      end

      it "renders text at positions with layer sender address" do
        letter.update!(heading: true)
        group.contact.destroy!
        layer.update!(town: "Wanaka", zip_code: '4242', address: "Lakeview 42")

        expect(text_with_position).to match_array [
          [71, 765, "Bottom One"],
          [71, 754, "Lakeview 42"],
          [71, 744, "4242 Wanaka"],
          [71, 687, "Bottom Member"],
          [71, 676, "Greatstreet 345"],
          [71, 666, "3456 Greattown"],
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
        letter.update!(heading: true, group: groups(:top_group))
        layer.update!(town: "Wanaka", address: "Lakeview 42", zip_code: "4242", town: "Bern")
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
          [71, 687, "Bottom Member"],
          [71, 676, "Greatstreet 345"],
          [71, 666, "3456 Greattown"],
          [71, 531, "Information"],
          [71, 502, "Hallo"],
          [71, 481, "Wir laden "],
          [111, 481, "dich"],
          [130, 481, " ein! "],
          [71, 460, "Bis bald"],
          [71, 687, "Top Leader"],
          [71, 676, "Funkystreet 42"],
          [71, 666, "4242 Supertown"],
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
          [71, 687, "Bottom Member"],
          [71, 676, "Greatstreet 345"],
          [71, 666, "3456 Greattown"],
          [71, 687, "Top Leader"],
          [71, 676, "Funkystreet 42"],
          [71, 666, "4242 Supertown"],
        ]
        expect(stamps.keys).to eq [:render_header, :render_subject, :render_content]
      end

      it "falls back to normal rending if stamping fails because content is to big" do
        letter.body = Faker::Lorem.paragraphs(number: 100)
        options[:stamped] = true
        expect(text_with_position).to be_present
        expect(stamps).to be_nil
      end
    end
  end

  context 'household addresses' do

    let(:recipients) { [people(:bottom_member)] }

    it 'creates only one letter per household' do
    end
  end

  private

  def text_with_position
    analyzer.positions.each_with_index.collect do |p, i|
      p.collect(&:round) + [analyzer.show_text[i]]
    end
  end
end
