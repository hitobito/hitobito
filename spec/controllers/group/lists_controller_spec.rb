require 'spec_helper'

describe Group::ListsController do
  it 'fails without token' do
    get :index, format: :json
    expect(response.status).to be(401)
  end

  it 'works with user login' do
    sign_in(people(:top_leader))
    get :index, format: :json
    expect(response.status).to be(200)
  end

  it 'works with token' do
    token = service_tokens(:permitted_top_group_token)
    get :index, params: { token: token.token }, format: :json
    expect(response.status).to be(200)
    expect(JSON.parse(response.body)['groups']).to have(9).items
  end
end
