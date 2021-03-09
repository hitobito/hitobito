# frozen_string_literal: true

require 'spec_helper'

describe Api::CorsCheck do
  subject { described_class.new(request) }
  let(:request) { ActionController::TestRequest.create({}) }
  let(:origin) { 'http://localhost' }
  let(:user) { people(:bottom_member) }

  let(:oauth_token) { nil }
  let(:service_token) { nil }

  before do
    allow_any_instance_of(Authenticatable::Tokens).to receive(:oauth_token) { oauth_token }
    allow_any_instance_of(Authenticatable::Tokens).to receive(:service_token) { service_token }
  end

  context 'with no tokens specified' do
    it 'should not be allowed by default' do
      expect(subject.allowed?(origin)).to be false
    end

    it 'should be allowed if there exists any CorsOrigin with that origin' do
      Fabricate(:cors_origin, origin: origin)

      expect(subject.allowed?(origin)).to be true
    end
  end

  context 'with OAuth token specified' do
    let(:oauth_token) { Fabricate(:access_token, application: application, resource_owner_id: user.id) }

    context 'with api scope' do
      let(:application) { Fabricate(:application, scopes: 'api') }

      it 'should not be allowed by default' do
        expect(subject.allowed?(origin)).to be false
      end

      it 'should be allowed if there exists a corresponding CorsOrigin on the application' do
        Fabricate(:cors_origin, origin: origin, auth_method: application)

        expect(subject.allowed?(origin)).to be true
      end

      it 'should not be allowed if the CorsOrigins of the application don\'t match'  do
        Fabricate(:cors_origin, origin: 'https://localhost', auth_method: application)
        Fabricate(:cors_origin, origin: origin)

        expect(subject.allowed?(origin)).to be false
      end
    end

    context 'without api scope' do
      let(:application) { Fabricate(:application, scopes: 'email') }

      it 'should not be allowed by default' do
        expect(subject.allowed?(origin)).to be false
      end

      it 'should not be allowed even if there exists any CorsOrigin with that origin' do
        Fabricate(:cors_origin, origin: origin, auth_method: application)

        expect(subject.allowed?(origin)).to be false
      end
    end
  end

  context 'with service token specified' do
    let(:service_token) { Fabricate(:service_token, layer: layer) }
    let(:layer) { groups(:bottom_layer_one) }

    it 'should not be allowed by default' do
      expect(subject.allowed?(origin)).to be false
    end

    it 'should be allowed if there exists a corresponding CorsOrigin on the service token' do
      Fabricate(:cors_origin, origin: origin, auth_method: service_token)

      expect(subject.allowed?(origin)).to be true
    end

    it 'should not be allowed if the CorsOrigins of the service token don\'t match'  do
      Fabricate(:cors_origin, origin: 'https://localhost', auth_method: service_token)
      Fabricate(:cors_origin, origin: origin)

      expect(subject.allowed?(origin)).to be false
    end
  end
end
