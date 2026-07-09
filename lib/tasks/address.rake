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
    task download_files: [:environment] do
      fail "Configure s3 for download" if ENV["RAILS_S3_BUCKETNAME"].blank?
      blobs = ActiveStorage::Attachment
        .where(record_type: "Delayed::Backend::ActiveRecord::Job")
        .order(created_at: :asc)
        .map(&:blob)

      blobs.each.with_index(1) do |blob, index|
        target = Rails.root.join("tmp/#{blob.created_at.to_date}-#{blob.filename}.tsv")
        puts target
        target.binwrite(blob.download)
      end
    end

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
        csv << %w[person_id version_id changed_at log zip_was zip_new changeset]
        versions.find_each do |version|
          person = version.main
          next unless person

          csv << [
            person.id,
            version.id,
            version.created_at,
            log_group_person_url(person.primary_group || Group.root, person, locale: :de, host:),
            version.changeset["zip_code"].to_a.first,
            version.changeset["zip_code"].to_a.last,
            version.changeset
          ]
        end
      end
      puts "Written changes to #{file}"
    end
  end
end
