# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

namespace :graphiti do
  desc 'Generate Graphiti schema'
  task generate_schema: :environment do
    # make sure we have all graphiti resources loaded
    Rails.application.eager_load!
    Dir.glob("#{Rails.root}/app/resources/**/*.rb").each { |f| require f }

    # generate schema.json and write to file
    schema = JSON.pretty_generate(Graphiti::Schema.generate)
    File.write("#{Rails.root}/swagger/graphiti-schema.json", schema)
  end

  desc "Generate swagger.yaml from graphiti schema"
  task generate_swagger: :environment do
    generator = Graphiti::OpenApi::Generator.new
    swagger_file = Rails.root.join('swagger', 'swagger.yaml')
    swagger_file.write(generator.to_openapi(format: :yaml))
  end
end
