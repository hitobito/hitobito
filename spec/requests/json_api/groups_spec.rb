# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'swagger_helper'
# require_relative 'group_schema'

RSpec.describe 'json_api/groups', type: :request do
  let(:'X-TOKEN') { service_tokens(:permitted_top_layer_token).token }
  let(:token) { service_tokens(:permitted_top_layer_token).token }
  let(:data) { JSON.parse(response.body).dig('data') }
  let(:include) { [] }

  path '/api/groups' do
    get('list groups') do
      parameter(
        name: 'include',
        in: :query,
        required: false,
        explode: false,
        schema: {
          type: :array,
          enum: %w(contact creator updater deleter parent layer_group),
          nullable: true
        }
      )

      parameter(name: 'extra_fields[groups]', in: :query, required: false, schema: { type: :string, enum: %w(logo) })
      parameter(name: 'filter[type][eq]', in: :query, required: false, schema: { type: :string, enum: Group.all_types })
      parameter(name: 'filter[with_archived]', in: :query, required: false, schema: { type: :boolean })

      response(200, 'successful') do
        after do |example|
          example.metadata[:response][:content] = {
            'application/vnd.json+api' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(200, 'successful') do
        let(:include) { %w(contact creator updater deleter parent layer_group) }
        run_test!
      end

      response(200, 'successful') do
        let(:'extra_fields[groups]') { 'logo' }
        run_test! do
          expect(data.dig(0, 'attributes')).to have_key('logo')

        end
      end

      response(200, 'successful') do
        let(:'filter[type][eq]') { %w(Group::TopGroup) }
        run_test! do
          expect(data).to have(1).item
        end
      end

      response(200, 'successful') do
        let(:'filter[with_archived]') { 'true' }
        before { Group.first.update_columns(archived_at: Time.zone.now) }
        run_test! do
          expect(data.size).to eq Group.count
        end
      end
    end
  end

  path '/api/groups/{id}' do
    let(:id) { groups(:top_group).id }
    parameter name: :id, in: :path, type: :string

    get('fetch group') do
      response(200, 'successful') do
        run_test!
      end
    end
  end
end
