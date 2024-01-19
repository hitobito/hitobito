# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

shared_examples 'jsonapi authorized requests' do
  let(:token) { service_tokens(:permitted_top_layer_token).token }
  let(:params) { {} }
  let(:payload) { {} }

  def jsonapi_headers
    super.merge('X-TOKEN' => token)
  end

  context 'without authentication' do
    let(:token) { nil }
    it 'returns unauthorized' do
      make_request
      expect(response.status).to eq(401)
      expect(json['errors']).to include(include("code" => "unauthorized"))
    end
  end

end
