# frozen_string_literal: true

#  Copyright (c) 2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Export::Pdf::Messages::Letter::Content do

  let(:options) { {} }
  let(:top_leader) { people(:top_leader) }
  let(:recipient) do
    MessageRecipient
      .new(message: letter, person: top_leader)
  end
  let(:letter) { Message::Letter.new(body: 'simple text') }
  let(:pdf) { Prawn::Document.new }
  let(:analyzer) { PDF::Inspector::Text.analyze(pdf.render) }

  subject { described_class.new(pdf, letter, options) }

  context "salutation" do
    it "renders body" do
      subject.render(recipient)
      expect(text_with_position).to eq [[36, 485, "simple text"]]
    end

    it "prepends salutation if set" do
      letter.salutation = "default"
      subject.render(recipient)
      expect(text_with_position).to eq [
        [36, 485, "Hallo Top"],
        [36, 447, "simple text"]
      ]
    end

    it "prepends personal salutation applicable" do
      letter.salutation = :lieber_vorname
      top_leader.gender = "m"
      subject.render(recipient)
      expect(text_with_position).to eq [
        [36, 485, "Lieber Top"],
        [36, 447, "simple text"]
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
                                 household_address: true)
      end

      before do
        letter.update!(send_to_households: true, body: 'Lorem ipsum')
        recipient.update!(household_address: true)
        recipient.person.update!(household_key: household_key)
      end

      it "does not render personal salutation for letter with generic salutation" do
        subject.render(recipient)
        expect(text_with_position).to eq [
          [36, 485, 'Lorem ipsum']
        ]
      end

      it 'renders saluation for all household members' do
        letter.update!(salutation: :lieber_vorname)

        subject.render(recipient)
        expect(text_with_position).to eq [
          [36, 485, "Liebe*r Top, Liebe*r #{housemate1.first_name}"],
          [36, 447, 'Lorem ipsum']
        ]
      end

      it 'does not render other household members salutation if not in recipients' do
        letter.update!(salutation: :lieber_vorname)
        recipient2.destroy!

        subject.render(recipient)
        expect(text_with_position).to eq [
          [36, 485, 'Liebe*r Top'],
          [36, 447, 'Lorem ipsum']
        ]
      end
    end
  end

  context "stamping" do
    before do
      top_leader.gender = "m"
      letter.salutation = "default"
    end

    let(:stamps) { pdf.instance_variable_get('@stamp_dictionary_registry') }

    it "has positions for salutation and text" do
      subject.render(recipient)
      pdf.start_new_page
      subject.render(recipient)
      expect(text_with_position).to eq [
        [36, 485, "Hallo Top"],
        [36, 447, "simple text"],
        [36, 485, "Hallo Top"],
        [36, 447, "simple text"]
      ]
      expect(stamps).to be_nil
    end

    it "has stamps for content" do
      options[:stamped] = true
      subject.render(recipient)
      pdf.start_new_page
      subject.render(recipient)
      expect(text_with_position).to eq [
        [36, 485, "Hallo Top"],
        [36, 485, "Hallo Top"],
      ]
      expect(stamps.keys).to eq [:render_content]
    end

    it "has stamps for different salutations and content" do
      options[:stamped] = true
      subject.render(recipient)
      pdf.start_new_page
      subject.render(MessageRecipient.new(person: Person.new))
      expect(stamps.keys).to eq [:render_content, :salutation_generic]
      # TODO: Unsure why in this case font in analyzer is empty
      # expect(text_with_position).to be_empty #
    end
  end

  def text_with_position
    analyzer.positions.each_with_index.collect do |p, i|
      p.collect(&:round) + [analyzer.show_text[i]]
    end
  end
end
