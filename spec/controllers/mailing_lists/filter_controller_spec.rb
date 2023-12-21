# frozen_string_literal: true

#  Copyright (c) 2012-2023, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Subscriber::FilterController do
  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }
  let(:mailing_list) { mailing_lists(:top_group) }

  before { sign_in(top_leader) }

  describe 'GET edit' do
    render_views

    it 'renders the form' do
      get :edit, params: { group_id: mailing_list.group.id, mailing_list_id: mailing_list.id }

      expect(response).to render_template("subscriber/filter/_form")
      Person::LANGUAGES.values.each { |language| expect(response.body).to have_content(language) }
    end
  end

  describe 'PUT update' do
    let(:filters) do
      {
        language: { "allowed_values" => %w[de fr] },
        attributes: { "1699698452786" => {"constraint" => "greater", "key" => "years", "value" => "16" } }
      }
    end

    it 'sets the filter values' do
      put :update, params: { group_id: mailing_list.group.id, mailing_list_id: mailing_list.id, filters: filters }

      expect(response).to redirect_to(group_mailing_list_subscriptions_path(group_id: mailing_list.group.id,
                                                                            id: mailing_list.id))

      filter_chain = mailing_list.reload.filter_chain
      expect(filter_chain[:language]).to be_a(Person::Filter::Language)
      expect(filter_chain[:language].args).to eq(filters[:language].deep_stringify_keys)
      expect(filter_chain[:language].allowed_values).to contain_exactly('de', 'fr')
      expect(filter_chain[:attributes]).to be_a(Person::Filter::Attributes)
      expect(filter_chain[:attributes].args).to eq(filters[:attributes].deep_stringify_keys)
    end
  end
end
