# frozen_string_literal: true

require 'spec_helper'

describe Authenticatable::Tokens do
  subject { described_class.new(request, params) }
  let(:request) { ActionController::TestRequest.create({}) }
  let(:params) { {}.with_indifferent_access }
  let(:headers) { {}.with_indifferent_access }
  let(:user) { people(:bottom_member) }

  before do
    allow(request).to receive(:parameters) { params }
    allow(request).to receive(:headers) { env_header_format(headers) }
    allow(request).to receive(:authorization) { headers.fetch(:Authorization, nil) }
  end

  def env_header_format(headers)
    return headers unless headers.any?
    headers
        .merge(headers.map { |k, v| { "HTTP_#{k.to_s.underscore.upcase}": v } }.reduce(:merge))
        .with_indifferent_access
  end

  context 'with no tokens specified' do
    it 'should return no OAuth token' do
      expect(subject.oauth_token).to be_nil
    end

    it 'should return no service token' do
      expect(subject.service_token).to be_nil
    end

    it 'should return no personal user token' do
      expect(subject.user_from_token).to be_nil
    end
  end

  context 'with OAuth token specified' do
    let(:application) { Fabricate(:application) }
    let(:token) { Fabricate(:access_token, application: application, resource_owner_id: user.id) }

    context 'via query parameters' do
      let(:params) { { access_token: token.token }.with_indifferent_access }

      it 'should return OAuth token' do
        expect(subject.oauth_token.id).to be(token.id)
      end

      it 'should return no service token' do
        expect(subject.service_token).to be_nil
      end

      it 'should return no personal user token' do
        expect(subject.user_from_token).to be_nil
      end
    end

    context 'via headers' do
      let(:headers) { { Authorization: "Bearer #{token.token}" } }

      it 'should return OAuth token' do
        expect(subject.oauth_token.id).to be(token.id)
      end

      it 'should return no service token' do
        expect(subject.service_token).to be_nil
      end

      it 'should return no personal user token' do
        expect(subject.user_from_token).to be_nil
      end
    end

    context 'should prefer headers over query parameters' do
      let(:application2) { Fabricate(:application) }
      let(:user2) { people(:top_leader) }
      let(:token2) { Fabricate(:access_token, application: application2, resource_owner_id: user2.id) }

      let(:params) { { access_token: token.token }.with_indifferent_access }
      let(:headers) { { Authorization: "Bearer #{token2.token}" } }

      it '' do
        expect(subject.oauth_token.id).to be(token2.id)
      end
    end
  end

  context 'with service token specified' do
    let(:layer) { groups(:bottom_layer_one) }
    let(:token) { Fabricate(:service_token, layer: layer) }

    context 'via query parameters' do
      let(:params) { { token: token.token }.with_indifferent_access }

      it 'should return no OAuth token' do
        expect(subject.oauth_token).to be_nil
      end

      it 'should return service token' do
        expect(subject.service_token.id).to be(token.id)
      end

      it 'should return no personal user token' do
        expect(subject.user_from_token).to be_nil
      end
    end

    context 'via headers' do
      let(:headers) { { 'X-Token': token.token } }

      it 'should return no OAuth token' do
        expect(subject.user_from_token).to be_nil
      end

      it 'should return service token' do
        expect(subject.service_token.id).to be(token.id)
      end

      it 'should return no personal user token' do
        expect(subject.user_from_token).to be_nil
      end
    end

    context 'should prefer headers over query parameters' do
      let(:layer2) { groups(:bottom_layer_two) }
      let(:token2) { Fabricate(:service_token, layer: layer) }

      let(:params) { { token: token.token }.with_indifferent_access }
      let(:headers) { { 'X-Token': token2.token } }

      it '' do
        expect(subject.service_token.id).to be(token2.id)
      end
    end
  end

  context 'with personal user tokens specified' do
    let(:token) { user.token }

    before do
      user.update(authentication_token: 'my-access-token')
    end

    context 'via query parameters' do
      let(:params) { { user_email: user.email, user_token: user.authentication_token }.with_indifferent_access }

      it 'should return no OAuth token' do
        expect(subject.oauth_token).to be_nil
      end

      it 'should return no service token' do
        expect(subject.service_token).to be_nil
      end

      it 'should return user' do
        expect(subject.user_from_token.id).to be(user.id)
      end
    end

    context 'via headers' do
      let(:headers) { { 'X-User-Email': user.email, 'X-User-Token': user.authentication_token } }

      it 'should return no OAuth token' do
        expect(subject.oauth_token).to be_nil
      end

      it 'should return no service token' do
        expect(subject.service_token).to be_nil
      end

      it 'should return user' do
        expect(subject.user_from_token.id).to be(user.id)
      end
    end

    context 'should prefer headers over query parameters' do
      let(:user2) { people(:top_leader) }
      let(:token2) { user2.token }

      before do
        user2.update(authentication_token: 'another-access-token')
      end

      let(:params) { { user_email: user.email, user_token: user.authentication_token }.with_indifferent_access }
      let(:headers) { { 'X-User-Email': user2.email, 'X-User-Token': user2.authentication_token } }

      it '' do
        expect(subject.user_from_token.id).to be(user2.id)
      end
    end
  end
end
