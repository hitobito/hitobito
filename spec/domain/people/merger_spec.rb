# frozen_string_literal: true

require 'spec_helper'

describe People::Merger do

  let(:person) { Fabricate(:person) }
  let(:doublet) { Fabricate(:person_with_address_and_phone) }

  let(:merger) { described_class.new(@src_person_id, @dst_person_id) }

  context 'merge people' do

    it 'merges two people and it\'s associations' do
      @src_person_id = doublet.id
      @dst_person_id = person.id

      orig_nickname = person.nickname
      orig_first_name = person.first_name
      orig_last_name = person.last_name
      orig_email = person.email

      expect do
        merger.merge!
      end.to change(Person, :count).by(-1)

      person.reload
      expect(person.nickname).to eq(orig_nickname)
      expect(person.first_name).to eq(orig_first_name)
      expect(person.last_name).to eq(orig_last_name)
      expect(person.email).to eq(orig_email)
      expect(person.address).to eq(doublet.address)
      expect(person.town).to eq(doublet.town)
      expect(person.zip_code).to eq(doublet.zip_code)
      expect(person.country).to eq(doublet.country)

      expect(Person.where(id: doublet.id)).not_to exist
    end

  end

end
