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

  desc "Split Addresses"
  task :split, [:limit] => [:environment] do |_, args|
    limit = args.fetch(:limit, -1).to_i

    require "csv"
    header = CSV.generate(col_sep: ";") do |csv|
      csv << ["Typ", "id", "alte Adresse", "Ergebnis", "c/o", "Strasse", "Hausnummer", "Postfach"]
    end
    puts header

    Rake::Task[:"address:convert"].execute(model: Person, limit: limit)

    begin
      previous = Group.archival_validation
      Group.archival_validation = false

      Rake::Task[:"address:convert"].execute(model: Group, limit: limit)
    ensure
      Group.archival_validation = previous
    end
  end

  task :convert, [:model, :limit] => [:environment] do |_, args|
    limit = args.fetch(:limit, -1).to_i
    model = args.fetch(:model).then do |class_or_string|
      if class_or_string.respond_to?(:safe_constantize)
        class_or_string.safe_constantize
      elsif class_or_string.is_a?(Class)
        class_or_string
      else
        raise ArgumentError, "Task needs a model as class or string to work"
      end
    end

    name = model.name.pluralize
    scope = model.where.not(address: nil).where.not(address: "")

    count = scope.count
    errors = []
    fails = []

    warn "Converting Addresses of #{count} #{name}"

    scope.find_each do |contactable|
      AddressConverter.convert(
        contactable,
        success: -> { $stderr.print(".") },
        failed: ->(info) { $stderr.print("F"); fails << info }, # rubocop:disable Style/Semicolon
        incomplete: ->(info) { $stderr.print("E"); errors << info } # rubocop:disable Style/Semicolon
      )

      if limit.positive? && (errors.size + fails.size) >= limit
        errors << ["XXXXXXX", "more than #{limit} errors", {reason: "ABORTED"}]
        break
      end
    end

    $stderr.print("\n")

    # reporting
    require "csv"
    report = CSV.generate(col_sep: ";") do |csv|
      errors.each do |id, old_addr, new_addr|
        csv << [name, id, old_addr, "partial", *new_addr.values]
      end
      fails.each do |id, old_addr|
        csv << [name, id, old_addr, "failed", nil, nil, nil, nil]
      end
    end
    puts report if report.present?

    warn "#{name}: #{count}"
    warn "Errors: #{errors.size}"
    warn "Fails: #{fails.size}"
  end
end
