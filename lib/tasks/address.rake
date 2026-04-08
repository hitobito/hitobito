# frozen_string_literal: true

#  Copyright (c) 2012-2024, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

namespace :address do
  desc "Import Post Addresses"
  task import: [:environment] do
    Address::Importer.new.run
  end

  namespace :sync do
    desc "Export Papertrail Verions create from AddressSynchronizationJob"
    task export_changes: [:environment] do
      file = Rails.root.join("tmp", "address_sync_changes.csv")
      host = ENV.fetch("RAILS_HOST_NAME", "localhost:3000")
      include Hitobito::Application.routes.url_helpers

      versions = PaperTrail::Version
        .where(whodunnit_type: "AddressSynchronizationJob")
        .where.not(object_changes: nil)
        .includes(:item)
      CSV.open(file, "wb") do |csv|
        csv << %w[version_id log zip_was zip_new changeset changed_at]
        versions.find_each do |version|
          person = version.main
          next unless person

          csv << [
            version.id,
            log_group_person_url(person.primary_group || Group.root, person, locale: :de, host:),
            version.changeset["zip_code"].to_a.first,
            version.changeset["zip_code"].to_a.last,
            version.changeset,
            version.created_at
          ]
        end
      end
      puts "Written changes to #{file}"
    end
  end
end
