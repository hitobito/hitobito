require 'swagger_helper'

RSpec.describe 'json_api/people', type: :request do

  path '/api/people' do

    get('list people') do
      response(200, 'successful') do
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end
  end
end
