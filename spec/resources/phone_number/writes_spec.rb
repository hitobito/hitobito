require 'spec_helper'

RSpec.describe PhoneNumberResource, type: :resource do
  describe 'creating' do
    let!(:person) { Fabricate(:person, birthday: Date.today, gender: 'm') }

    let(:payload) do
      {
        data: {
          type: 'phone_numbers',
          attributes: Fabricate.attributes_for(:phone_number).merge(
            contactable_id: person.id,
            contactable_type: 'Person',
            number: '0780000000'
          )
        }
      }
    end

    let(:instance) do
      PhoneNumberResource.build(payload)
    end

    it 'works' do
      expect {
        expect(instance.save).to eq(true), instance.errors.full_messages.to_sentence
      }.to change { PhoneNumber.count }.by(1)

      new_phone_number = PhoneNumber.last
      expect(new_phone_number.contactable).to eq person
      expect(new_phone_number.number).to eq '+41 78 000 00 00'
    end
  end

  describe 'updating' do
    let!(:phone_number) { Fabricate(:phone_number, number: '0780000000') }

    let(:payload) do
      {
        id: phone_number.id.to_s,
        data: {
          id: phone_number.id.to_s,
          type: 'phone_numbers',
          attributes: {
            number: '0780000001'
          }
        }
      }
    end

    let(:instance) do
      PhoneNumberResource.find(payload)
    end

    it 'works (add some attributes and enable this spec)' do
      expect {
        expect(instance.update_attributes).to eq(true)
      }.to change { phone_number.reload.number }.to('+41 78 000 00 01')
    end
  end

  describe 'destroying' do
    let!(:phone_number) { Fabricate(:phone_number) }

    let(:instance) do
      PhoneNumberResource.find(id: phone_number.id)
    end

    it 'works' do
      expect {
        expect(instance.destroy).to eq(true)
      }.to change { PhoneNumber.count }.by(-1)
    end
  end
end
