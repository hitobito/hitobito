# frozen_string_literal: true

#  Copyright (c) 2022-2023, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'swagger_helper'
require_relative 'person_schema'

RSpec.describe 'json_api/people', type: :request do
  let(:'X-TOKEN') { service_tokens(:permitted_top_layer_token).token }
  let(:token) { service_tokens(:permitted_top_layer_token).token }
  let(:include) { [] }

  path '/api/people' do

    # add pagination
    # add filter for updated_at

    get('list people') do
      parameter({
        name: 'include',
        in: :query,
        required: false,
        explode: false,
        schema: {
          type: :array,
          enum: [
            'phone_numbers',
            'social_accounts',
            'additional_emails',
            'roles',
          ],
          nullable: true
        }
      })
      parameter({name: 'filter[updated_at][gte]', in: :query, required: false, schema: { type: :string, format: :date}})

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
        let(:include) { %w(phone_numbers social_accounts additional_emails roles) }
        run_test!
      end
    end
  end

  path '/api/people/{id}' do
    let(:id) { people(:bottom_member).id }
    parameter name: :id, in: :path, type: :string

    get('fetch person') do
      parameter({
        name: 'include',
        in: :query,
        required: false,
        explode: false,
        schema: {
          type: :array,
          enum: %w(
            phone_numbers social_accounts additional_emails
            roles roles.layer_group roles.group roles.group.parent roles.group.layer_group
          ),
          nullable: true
        }
      })

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
        let(:include) do
          %w(
            phone_numbers social_accounts additional_emails
            roles roles.layer_group roles.group roles.group.parent roles.group.layer_group
          )
        end
        run_test!
      end
    end

    patch('update person') do
      parameter name: :data, in: :body, schema: JsonApi::PersonSchema.read

      response(200, 'successful') do
        let(:data) do
          { data: {
              id: id,
              type: 'people',
              attributes:
              { first_name: 'Bobby' }
            }
          }
        end

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
