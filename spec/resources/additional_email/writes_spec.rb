require 'spec_helper'

RSpec.describe AdditionalEmailResource, type: :resource do
  describe 'creating' do
    let!(:person) { Fabricate(:person, birthday: Date.today, gender: 'm') }

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
    let!(:additional_email) { Fabricate(:additional_email) }

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

    it 'works (add some attributes and enable this spec)' do
      expect {
        expect(instance.update_attributes).to eq(true)
      }.to change { additional_email.reload.email }.to('mis-grosi@example.com')
    end
  end

  describe 'destroying' do
    let!(:additional_email) { Fabricate(:additional_email) }

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
