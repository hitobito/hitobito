# frozen_string_literal: true

#  Copyright (c) 2021, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Pdf::Messages::LetterWithInvoice::DonationConfirmation do
  let(:top_leader) { people(:top_leader) }
  let(:recipient) do
    MessageRecipient
      .new(message: letter_with_invoice, person: bottom_member)
  end
  let(:top_layer) { groups(:top_layer) }
  let(:bottom_member) { people(:bottom_member) }

  let(:options) { {} }
  let(:letter_with_invoice) { messages(:with_invoice) }
  let(:pdf) { Export::Pdf::Document.new.pdf }
  let(:analyzer) { PDF::Inspector::Text.analyze(pdf.render) }

  subject { described_class.new(pdf, letter_with_invoice, recipient, options) }

  context "donation confirmation" do
    let(:stamps) { pdf.instance_variable_get(:@donation_confirmation_text) }

    it "renders body with donation confirmation sum" do
      fabricate_donation(200, 1.year.ago)
      fabricate_donation(500, 1.year.ago)
      fabricate_donation(1000, 2.year.ago)

      letter_with_invoice.salutation = "sehr_geehrter_titel_nachname"
      top_leader.gender = "m"
      bottom_member.gender = "m"

      subject.render

      expect(text_with_position.pretty_inspect).to eq [
        [57, 770, "Spenden an Top"],
        [57, 749, "Hallo Bottom"],
        [57, 724, "Wir danken Ihnen für Ihr Vertrauen und Ihr geschätztes Engagement!"],
        [57, 699, "Spendenbestätigung #{1.year.ago.year}"],
        [57, 673, "#{1.year.ago.year} haben wir von"],
        [57, 651, "Bottom, Member"],
        [57, 639, "Greatstreet 345"],
        [57, 626, "3456 Greattown"],
        [57, 604, "Spenden erhalten in der Höhe von"],
        [57, 582, "CHF 700.00"]
      ].pretty_inspect
    end

    it "renders nothing with zero donation value" do
      subject.render

      expect(text_with_position).to be_empty
    end
  end

  private

  def text_with_position
    analyzer.positions.each_with_index.collect do |p, i|
      p.collect(&:round) + [analyzer.show_text[i]]
    end
  end

  def fabricate_donation(amount, received_at = 1.year.ago)
    invoice = Fabricate(:invoice, due_at: 10.days.from_now, creator: top_leader, recipient: bottom_member, group: top_layer, state: :payed)
    Payment.create!(amount: amount, received_at: received_at, invoice: invoice)
  end
end
