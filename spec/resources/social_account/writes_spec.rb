require 'spec_helper'

RSpec.describe SocialAccountResource, type: :resource do
  describe 'creating' do
    let!(:person) { Fabricate(:person, birthday: Date.today, gender: 'm') }

    let(:payload) do
      {
        data: {
          type: 'social_accounts',
          attributes: Fabricate.attributes_for(:social_account).merge(
            contactable_id: person.id,
            contactable_type: 'Person',
            name: 'mis-grosi'
          )
        }
      }
    end

    let(:instance) do
      SocialAccountResource.build(payload)
    end

    it 'works' do
      expect {
        expect(instance.save).to eq(true), instance.errors.full_messages.to_sentence
      }.to change { SocialAccount.count }.by(1)

      new_social_account = SocialAccount.last
      expect(new_social_account.contactable).to eq person
      expect(new_social_account.name).to eq 'mis-grosi'
    end
  end

  describe 'updating' do
    let!(:social_account) { Fabricate(:social_account) }

    let(:payload) do
      {
        id: social_account.id.to_s,
        data: {
          id: social_account.id.to_s,
          type: 'social_accounts',
          attributes: {
            name: 'mis-grosi'
          }
        }
      }
    end

    let(:instance) do
      SocialAccountResource.find(payload)
    end

    it 'works (add some attributes and enable this spec)' do
      expect {
        expect(instance.update_attributes).to eq(true)
      }.to change { social_account.reload.name }.to('mis-grosi')
    end
  end

  describe 'destroying' do
    let!(:social_account) { Fabricate(:social_account) }

    let(:instance) do
      SocialAccountResource.find(id: social_account.id)
    end

    it 'works' do
      expect {
        expect(instance.destroy).to eq(true)
      }.to change { SocialAccount.count }.by(-1)
    end
  end
end
