require 'swagger_helper'

RSpec.describe 'json_api/people', type: :request do

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
          ],
          nullable: true,
          description: 'Contactables'
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
        let(:include) { %w(phone_numbers social_accounts additional_emails) }
        run_test!
      end
    end
  end
end
