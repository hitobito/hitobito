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
  let(:include) { [] }

  path '/api/groups' do

    # add pagination
    # add filter for updated_at

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

      parameter(name: 'extra_fields', in: :query, required: false, schema: { type: :string, enum: %w(logo) })
      parameter(name: 'filter[type][eq]', in: :query, required: false, schema: { type: :string, enum: Group.all_types })

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
    end
  end

  path '/api/groups/{id}' do
    let(:id) { groups(:top_group).id }
    parameter name: :id, in: :path, type: :string

    get('fetch group') do
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
    end
  end
end
