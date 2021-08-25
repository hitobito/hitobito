# frozen_string_literal: true

#  Copyright (c) 017, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Export::Tabular::Messages::LettersWithInvoice::Row do
  let(:top_layer) { groups(:top_layer) }
  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:top_leader) }
  let(:invoice) { Fabricate(:invoice, due_at: 10.days.from_now, creator: top_leader,
                            recipient: bottom_member, group: top_layer, ) }

  subject { described_class.new(invoice) }

  context 'invoice attributes' do
    it 'are present' do
      expect(subject.fetch(:esr_number)).to eq(invoice.esr_number)
      expect(subject.fetch(:recipient_email)).to eq(invoice.recipient_email)
      expect(subject.fetch(:recipient_address)).to eq(invoice.recipient_address)
      expect(subject.fetch(:reference)).to eq(invoice.reference)
      expect(subject.fetch(:total)).to eq(invoice.total)
    end
  end

  context 'recipient attributes' do
    it 'are present' do
      # bottom_member.update(salutation: 'liebe/r Name Vorname')

      expect(subject.fetch(:first_name)).to eq(bottom_member.first_name)
      expect(subject.fetch(:last_name)).to eq(bottom_member.last_name)
      expect(subject.fetch(:company_name)).to eq(bottom_member.company_name)
      expect(subject.fetch(:company)).to eq('nein')
      expect(subject.fetch(:email)).to eq(bottom_member.email)
      expect(subject.fetch(:address)).to eq(bottom_member.address)
      expect(subject.fetch(:zip_code)).to eq(bottom_member.zip_code)
      expect(subject.fetch(:town)).to eq(bottom_member.town)
      expect(subject.fetch(:country)).to eq(bottom_member.country)
      expect(subject.fetch(:gender)).to eq(bottom_member.gender)
      expect(subject.fetch(:birthday)).to eq(bottom_member.birthday)
      expect(subject.fetch(:salutation)).to eq('Hallo Top')
      expect(subject.fetch(:title)).to eq(nil)
      expect(subject.fetch(:correspondence_language)).to eq(nil)
      expect(subject.fetch(:household_key)).to eq(bottom_member.household_key)
    end
  end
end
