# frozen_string_literal: true

require 'spec_helper'

describe AddressesController do

  before { sign_in(people(:top_leader)) }

  let(:person)   { people(:bottom_member) }

  context 'GET query' do

    it 'finds addresses street without number' do
      address = addresses(:bs_bern)
      get :query, params: { q: address.to_s[0..5] }

      expect(@response.body).to include(address.street_short)
      expect(@response.body).to include(address.town)
      expect(@response.body).to include(address.zip_code.to_s)
    end

    it 'finds addresses street with number' do
      address = addresses(:bs_bern)
      get :query, params: { q: "#{address.to_s[0..5]} #{address.numbers.first.to_s}" }

      expect(@response.body).to include(address.street_short)
      expect(@response.body).to include(address.town)
      expect(@response.body).to include(address.zip_code.to_s)
      expect(@response.body).to include(address.numbers.first.to_s)
      JSON.parse(@response.body).each do |response|
        number = response['number']
        label = response['label']
        expect(address.numbers).to include(number)
        expect(label).to eq("Belpstrasse #{number} 3007 Bern")
      end
    end
  end
end
