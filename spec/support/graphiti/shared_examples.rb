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

shared_examples 'graphiti schema file is up to date' do
  it do
    context_root = Pathname.new(Dir.pwd)

    # If no resources are defined, we assume the current context has no customizations
    # of the base api. This can be the case for wagons which use the core api unchanged.
    # In this case we don't need to check the schema file as it gets already checked in
    # the core.
    next unless context_root.glob('app/resources/**/*.rb').present?

    # There are specific schema.json files for the core and the wagons.
    # We need to configure graphiti to use the correct schema.json file depending on the
    # context where this spec is run.
    Graphiti.configure do |config|
      config.schema_path = context_root.join('spec', 'support', 'graphiti', 'schema.json')
    end

    expect(Graphiti.config.schema_path).to exist

    old_schema = Digest::MD5.hexdigest(JSON.parse(Graphiti.config.schema_path.read).to_json)
    current_schema = Digest::MD5.hexdigest(Graphiti::Schema.generate.to_json)

    expect(old_schema).to eq(current_schema), <<~MSG
      The schema file is outdated: #{Graphiti.config.schema_path.relative_path_from(Pathname.new(Dir.pwd).parent)}
      Please run `bundle exec rake graphiti:schema:generate` and commit the file to the git repository.
    MSG
  end
end
