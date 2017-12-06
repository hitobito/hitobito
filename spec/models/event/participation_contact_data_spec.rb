# encoding: utf-8

#  Copyright (c) 2012-2017, Pfadibewegung Schweiz. This file is part of
#  hitobito_youth and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_youth.

require 'spec_helper'

describe Event::ParticipationContactData do

  let(:event) { events(:top_event) }
  let(:person) { people(:top_leader) }

  let(:attributes) do
    h = ActiveSupport::HashWithIndifferentAccess.new
    h.merge({ first_name: 'John', last_name: 'Gonzales',
      email: 'top_leader@example.com',
      nickname: '' })
  end

  context 'validations' do

    it 'validates contact attributes' do
      contact_data = participation_contact_data(attributes)
      event.update!(required_contact_attrs: ['nickname'])

      expect(contact_data).not_to be_valid
      expect(contact_data.errors.full_messages.first).to eq('Übername muss ausgefüllt werden')
    end

    it 'validates person attributes' do
      attrs = attributes
      attrs[:birthday] = 'invalid'
      contact_data = participation_contact_data(attrs)

      expect(contact_data).not_to be_valid
      expect(contact_data.errors.full_messages.first).to eq('Geburtstag ist kein gültiges Datum')
    end

    it 'can have a mandatory phone-number' do
      contact_data = participation_contact_data(attributes)
      event.update!(required_contact_attrs: ['phone_numbers'])

      expect(contact_data).not_to be_valid
      expect(contact_data.errors.full_messages.first).to eq('Telefonnummern muss ausgefüllt werden')

      contact_data = participation_contact_data(attributes.merge(phone_numbers: [PhoneNumber.create(number: '117', translated_label: 'Privat', public: false)]))
      event.update!(required_contact_attrs: ['phone_numbers'])
      expect(contact_data).to be_valid
    end

  end

  context 'update person data' do

    it 'updates person attributes' do
      contact_data = participation_contact_data(attributes)

      contact_data.save

      person.reload

      expect(person.first_name).to eq('John')
      expect(person.last_name).to eq('Gonzales')
    end

  end

  private

  def participation_contact_data(attributes)
    Event::ParticipationContactData.new(event, person, attributes)
  end

end
