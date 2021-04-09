require 'spec_helper'

describe Api::EventParticipationsController do
  let(:top_leader) { people(:top_leader) }

  it 'fails without token' do
    get :index, params: { person_id: top_leader.id }, format: :json
    expect(response.status).to be(401)
  end

  it 'works with user login' do
    sign_in(top_leader)
    get :index, params: { person_id: top_leader.id }, format: :json
    expect(response.status).to be(200)
  end

  it 'works with token' do
    token = service_tokens(:permitted_top_group_token)
    get :index, params: { person_id: top_leader.id, token: token.token }, format: :json
    expect(response.status).to be(200)
  end

  it 'returns all participations' do
    Fabricate(:event_participation, person: top_leader, active: true)
    token = service_tokens(:permitted_top_group_token)
    get :index, params: { person_id: top_leader.id, token: token.token }, format: :json
    expect(JSON.parse(response.body)['event_participations']).to have(1).items
  end
end
