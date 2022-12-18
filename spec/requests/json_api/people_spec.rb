require 'swagger_helper'

RSpec.describe 'json_api/people', type: :request do

  let(:'X-TOKEN') { service_tokens(:permitted_top_layer_token).token }
  let(:token) { service_tokens(:permitted_top_layer_token).token }
  let(:include) { [] }

  path '/api/people' do

    get('list people') do
      produces 'application/vnd.json+api'
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
end
