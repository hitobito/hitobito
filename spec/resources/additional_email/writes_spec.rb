# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe PhoneNumberResource, type: :resource do
  let!(:person) { subject.current_user }
  let!(:role) { Fabricate(Group::BottomLayer::Leader.name.to_sym, person: person, group: groups(:bottom_layer_one)) }

  describe 'creating' do
    let(:payload) do
      {
        data: {
          type: 'additional_emails',
          attributes: Fabricate.attributes_for(:additional_email).merge(
            contactable_id: person.id,
            contactable_type: 'Person',
            email: 'mis-grosi@example.com'
          )
        }
      }
    end

    let(:instance) do
      AdditionalEmailResource.build(payload)
    end

    it 'works' do
      expect {
        expect(instance.save).to eq(true), instance.errors.full_messages.to_sentence
      }.to change { AdditionalEmail.count }.by(1)

      new_additional_email = AdditionalEmail.last
      expect(new_additional_email.contactable).to eq person
      expect(new_additional_email.email).to eq 'mis-grosi@example.com'
    end
  end

  describe 'updating' do
    let!(:additional_email) { Fabricate(:additional_email, contactable: person) }

    let(:payload) do
      {
        id: additional_email.id.to_s,
        data: {
          id: additional_email.id.to_s,
          type: 'additional_emails',
          attributes: {
            email: 'mis-grosi@example.com'
          }
        }
      }
    end

    let(:instance) do
      AdditionalEmailResource.find(payload)
    end

    it 'works' do
      expect {
        expect(instance.update_attributes).to eq(true)
      }.to change { additional_email.reload.email }.to('mis-grosi@example.com')
    end
  end

  describe 'destroying' do
    let!(:additional_email) { Fabricate(:additional_email, contactable: person) }

    let(:instance) do
      AdditionalEmailResource.find(id: additional_email.id)
    end

    it 'works' do
      expect {
        expect(instance.destroy).to eq(true)
      }.to change { AdditionalEmail.count }.by(-1)
    end
  end
end
