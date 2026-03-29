# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

shared_examples "jsonapi authorized requests" do |person: :top_leader, required_scopes: []|
  let(:service_token) { service_tokens(:permitted_top_layer_token) }
  let(:token) { service_token.token }
  let(:params) { {} }
  let(:payload) { {} }

  def jsonapi_headers
    super.merge("X-TOKEN" => token)
  end

  def response_body = @body ||= JSON.parse(response.body).deep_symbolize_keys

  context "without authentication" do
    def jsonapi_headers
      super.without("X-TOKEN")
    end

    it "returns unauthorized" do
      make_request
      expect(response.status).to eq(401)
      expect(json["errors"]).to include(include("code" => "unauthorized"))
    end
  end

  context "with service token based authentication" do
    it "returns 200 for service token with correct scopes" do
      make_request
      expect(response.status).to be_between(200, 201).inclusive
    end

    required_scopes.each do |scope|
      it "returns unauthorized for token without #{scope}=true" do
        service_token.update!(scope => false)
        make_request
        expect(response.status).to eq(403)
        expect(json["errors"]).to include(include("code" => "forbidden"))
      end
    end
  end

  if person
    context "with session cookie based authentication" do
      def jsonapi_headers
        super.without("X-TOKEN")
      end

      let(:current_user) { people(person) }

      it "returns 200 for person with correct role" do
        sign_in(current_user)
        make_request
        expect(response.status).to be_between(200, 201).inclusive
      end
    end

    context "with OAuth based authentication" do
      def jsonapi_headers
        super.without("X-TOKEN").merge("Authorization" => "Bearer #{oauth_access_token&.token}")
      end

      let(:redirect_uri) { "urn:ietf:wg:oauth:2.0:oob" }
      let(:oauth_app) { Oauth::Application.create!(name: "MyApp", redirect_uri: redirect_uri) }
      let(:current_user) { people(person) }
      let(:oauth_access_token) do
        Oauth::AccessToken.create!(
          scopes: required_scopes.join(" "),
          token: "PermittedOAuthAccessToken",
          application_id: oauth_app.id,
          resource_owner_id: current_user&.id
        )
      end

      it "returns 200 for OAuth token with correct scopes" do
        make_request
        expect(response.status).to be_between(200, 201).inclusive
      end

      it "returns 200 for OAuth token with only api scope" do
        oauth_access_token.update!(scopes: "api")
        make_request
        expect(response.status).to be_between(200, 201).inclusive
      end

      required_scopes.each do |scope|
        it "returns unauthorized without scope #{scope}" do
          oauth_access_token.update!(scopes: (required_scopes - [scope]).join(" "))
          make_request
          expect(response.status).to eq(403)
        end
      end
    end
  end
end

shared_examples "graphiti schema file is up to date" do
  it "graphiti schema file is up to date" do
    context_root = Pathname.new(Dir.pwd)

    # If no resources are defined, we assume the current context has no customizations
    # of the base api. This can be the case for wagons which use the core api unchanged.
    # In this case we don't need to check the schema file as it gets already checked in
    # the core.
    next if context_root.glob("app/resources/**/*.rb").blank?

    # There are specific schema.json files for the core and the wagons.
    # We need to configure graphiti to use the correct schema.json file depending on the
    # context where this spec is run.
    Graphiti.configure do |config|
      config.schema_path = context_root.join("spec", "support", "graphiti", "schema.json")
    end

    expect(Graphiti.config.schema_path).to exist

    old_schema = Digest::MD5.hexdigest(JSON.parse(Graphiti.config.schema_path.read).to_json)
    current_schema = Digest::MD5.hexdigest(Graphiti::Schema.generate.to_json)

    expect(old_schema).to eq(current_schema), <<~MSG
      The schema file is outdated: #{Graphiti.config.schema_path.relative_path_from(Pathname.new(Dir.pwd).parent)}
      Please run `bundle exec rake graphiti:schema:generate` and commit the file to the git repository.
    MSG
  end

  describe "GET /api-docs", type: :request do
    it "openapi spec is valid" do
      get "/api/openapi.json"
      json = JSON.parse(response.body)
      expect(OpenApi::SchemaValidator.validate!(json, 3)).to be_truthy, <<~MSG
        The generated OpenAPI specification file does not conform to the official OpenAPI 3 standard.
        Please paste the output of /api/openapi.json or /api/openapi.yaml into
        https://editor.swagger.io, and fix all reported errors.
      MSG
    end
  end
end
