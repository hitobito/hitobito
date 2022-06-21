# frozen_string_literal: true

#  Copyright (c) 2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Export::Pdf::Messages::Letter::Content do

  let(:options) { {
    margin: Export::Pdf::Messages::Letter::MARGIN,
    page_size: 'A4',
    page_layout: :portrait,
    compress: true
  } }

  let(:top_leader) { people(:top_leader) }
  let(:recipient) do
    MessageRecipient
      .new(message: letter, person: top_leader)
  end
  let(:letter) { Message::Letter.new(body: 'simple text') }
  let(:pdf) { Prawn::Document.new(options) }
  let(:analyzer) { PDF::Inspector::Text.analyze(pdf.render) }

  subject { described_class.new(pdf, letter, options) }

  context "salutation" do
    it "renders body" do
      subject.render(recipient)
      expect(text_with_position).to eq [[71, 502, "simple text"]]
    end

    it "prepends salutation if set" do
      letter.salutation = "default"
      recipient.salutation = 'Hallo Top'
      subject.render(recipient)
      expect(text_with_position).to eq [
        [71, 502, "Hallo Top"],
        [71, 474, "simple text"]
      ]
    end

    it "prepends personal salutation applicable" do
      letter.salutation = :lieber_vorname
      recipient.salutation = 'Lieber Top'
      top_leader.gender = "m"
      subject.render(recipient)
      expect(text_with_position).to eq [
        [71, 502, "Lieber Top"],
        [71, 474, "simple text"]
      ]
    end

    it 'handles company?' do
    end

    context 'households' do
      let(:household_key) { 'household-abcd42' }
      let(:housemate1) { Fabricate(:person_with_address, household_key: household_key) }
      let(:letter) { messages(:letter) }
      let!(:recipient2) do
        MessageRecipient.create!(message: letter,
                                 person: housemate1,
                                 salutation: "Liebe*r #{housemate1.first_name}")
      end

      before do
        letter.update!(send_to_households: true, body: 'Lorem ipsum')
        recipient.update!(salutation: "Liebe*r #{recipient.person.first_name}")
        recipient.person.update!(household_key: household_key)
      end

      it "does not render personal salutation for letter with no salutation" do
        subject.render(recipient)
        expect(text_with_position).to eq [
          [71, 502, 'Lorem ipsum']
        ]
      end

      it 'renders saluation for all household members' do
        letter.update!(salutation: :lieber_vorname)
        recipient.update!(salutation: "Liebe*r Top, liebe*r #{housemate1.first_name}")

        subject.render(recipient)
        expect(text_with_position).to eq [
          [71, 502, "Liebe*r Top, liebe*r #{housemate1.first_name}"],
          [71, 474, 'Lorem ipsum']
        ]
      end

      it 'does not render other household members salutation if not in recipients' do
        letter.update!(salutation: :lieber_vorname)
        recipient2.destroy!

        subject.render(recipient)
        expect(text_with_position).to eq [
          [71, 502, 'Liebe*r Top'],
          [71, 474, 'Lorem ipsum']
        ]
      end
    end
  end

  context "stamping" do
    before do
      top_leader.gender = "m"
      letter.salutation = "default"
      recipient.salutation = "Hallo Top"
    end

    let(:stamps) { pdf.instance_variable_get('@stamp_dictionary_registry') }

    it "has positions for salutation and text" do
      subject.render(recipient)
      pdf.start_new_page
      subject.render(recipient)
      expect(text_with_position).to eq [
        [71, 502, "Hallo Top"],
        [71, 474, "simple text"],
        [71, 502, "Hallo Top"],
        [71, 474, "simple text"]
      ]
      expect(stamps).to be_nil
    end

    it "has stamps for content" do
      options[:stamped] = true
      subject.render(recipient)
      pdf.start_new_page
      subject.render(recipient)
      expect(text_with_position).to eq [
        [71, 502, "Hallo Top"],
        [71, 502, "Hallo Top"],
      ]
      expect(stamps.keys).to eq [:render_content]
    end
  end

  def text_with_position
    analyzer.positions.each_with_index.collect do |p, i|
      p.collect(&:round) + [analyzer.show_text[i]]
    end
  end
end
