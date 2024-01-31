# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module GraphitiSchemaSpecHelpers
  def self.up_to_date?
    ::RSpec.describe 'Graphiti Schema' do
      it 'file is up to date' do
        schema_path = Graphiti.config.schema_path
        relative_schema_path = schema_path.relative_path_from(Rails.root)
        error_msg =
          <<~MSG
            did you forget to check in the schema file?
            Run `rspec` to update the schema file and check in #{relative_schema_path}.
          MSG

        expect(schema_path).to exist, "Schema file does not exist, #{error_msg}"

        current_schema = Graphiti::Schema.generate.to_json
        old_schema = JSON.parse(schema_path.read).to_json

        expect(Digest::MD5.hexdigest(old_schema)).to eq(Digest::MD5.hexdigest(current_schema)),
          "Schema file is not up to date, #{error_msg}"
      end
    end
  end
end
