# frozen_string_literal: true

#  Copyright (c) 2024-2024, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'csv'

class AddressConverter
  STREET_HOUSENUMBER_REGEX = %r{^(.*?)[,?[:space:]*]?((?:\d+[-/])?\d+\s?\w?)?$}

  # complete flow for one contactable, with callbacks to be used from a rake-task
  def self.convert(contactable, success:, incomplete:, failed:) # rubocop:disable Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    conv = new(contactable)
    conv.split

    if conv.check
      begin
        result = conv.save
        success&.call()
      rescue
        result = false
        failed&.call(conv.failed_info)
      end

      result
    else
      failed&.call(conv.failed_info) if conv.failed?
      incomplete&.call(conv.incomplete_info) if conv.incomplete?

      false
    end
  end

  def initialize(contactable)
    @contactable = contactable # person or group

    @addr = @contactable[:address]
  end

  def split
    return @contactable if only_question_marks?

    extract_address_field_from(sanitized_address_lines)

    @contactable
  end

  def check
    same_address? ||
    same_complete_address? ||
    better_address? ||
    address_with_question_marks? ||
    only_question_marks?
  end

  def save
    @contactable.address = nil
    @contactable.save(validate: false)
  end

  def failed?
    structured_address.values.compact.blank?
  end

  def failed_info
    incomplete_info[0..2]
  end

  def incomplete?
    !check && !failed?
  end

  def incomplete_info
    [@contactable.id, @contactable.to_s, @addr, structured_address]
  end

  private

  # preparation

  def sanitized_address_lines
    @addr.lines
         .map { |line| line.gsub(/[[:space:]]+/, ' ').gsub(/\?+$/, '').strip.chomp }
         .reject { |line| line.empty? }
  end

  # parsing / extraction

  def extract_address_field_from(lines) # rubocop:disable Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/AbcSize
    case lines.count
    when 1
      only_street_and_number(lines.first)
    when 2
      if address_in_line(lines.last) # has side effect
        @contactable.address_care_of = lines.first.strip
      elsif address_in_line(lines.first)
        @contactable.postbox = lines.last.strip
      else
        only_street_and_number(lines.join(' '))
      end
    when 3
      if address_in_line(lines[1])
        @contactable.address_care_of = lines.first.strip
        @contactable.postbox = lines.last.strip
      end
    end
  end

  def address_in_line(line)
    only_street_and_number(line)
    return true if line == [@contactable.street,
                            @contactable.housenumber].compact.join(' ').presence

    @contactable.restore_attributes(%w(street housenumber))

    false
  end

  def only_street_and_number(line)
    matches = STREET_HOUSENUMBER_REGEX.match(line)
    @contactable.street = matches[1]&.strip
    @contactable.housenumber = matches[2]&.strip

    matches
  end

  # helper for checks

  def structured_address
    {
      care_of: @contactable.address_care_of,
      street: @contactable.street,
      number: @contactable.housenumber,
      postbox: @contactable.postbox
    }
  end

  def new_address
    [
      @contactable.address_care_of,
      [@contactable.street, @contactable.housenumber].compact.join(' ').presence,
      @contactable.postbox
    ].compact
  end

  def sanitized_address
    @addr.lines
         .map { |line| line.gsub(/[[:space:]]+/, ' ').strip }
         .reject { |line| line.empty? }
         .join("\n")
         .chomp(',')
  end

  # checks

  def same_address?
    sanitized_address == [@contactable.street, @contactable.housenumber].compact.join(' ').presence
  end

  def same_complete_address?
    sanitized_address == new_address.join("\n")
  end

  def better_address?
    sanitized_address == [@contactable.street, @contactable.housenumber].join ||
    sanitized_address == [@contactable.street, @contactable.housenumber].join(',')
  end

  def address_with_question_marks?
    sanitized_address.gsub(/\?+$/,
                           '').strip == [@contactable.street,
                                         @contactable.housenumber].compact.join(' ').presence
  end

  def only_question_marks?
    @addr =~ /^\?+$/
  end
end

class Splitter
  attr_reader :report

  def initialize(report)
    @report = report
    write_report("Database-Name: #{ActiveRecord::Base.connection.current_database}\n")
  end

  def split
    header = CSV.generate(col_sep: ';') do |csv|
      csv << ['Typ', 'id', 'Name', 'alte Adresse', 'Ergebnis', 'c/o', 'Strasse', 'Hausnummer',
              'Postfach']
    end
    write_report(header)

    handle_models(:convert_address)
  end

  def clean
    handle_models(:erase_address)
  end

  private

  def handle_models(method)
    send(method, Person)

    begin
      previous = Group.archival_validation
      Group.archival_validation = false

      send(method, Group)
    ensure
      Group.archival_validation = previous
    end
  end

  def with_address(model) = model.where.not(address: nil).where.not(address: '')

  def convert_address(model)
    name = model.name.pluralize
    scope = with_address(model)

    count = scope.count
    errors = []
    fails = []

    warn "Converting Addresses of #{count} #{name}"
    model.reset_column_information

    # convert to find_in_batches to flush after each batch
    total_batches = (count / 1000.0).ceil

    scope.find_in_batches(batch_size: 1000).with_index do |batch, number|
      puts "   -> splitting #{name}: Batch #{number + 1} / #{total_batches}"
      batch.each do |contactable|
        AddressConverter.convert(
          contactable,
          success: -> { $stderr.print('.') },
          failed: ->(info) { $stderr.print('F'); fails << info }, # rubocop:disable Style/Semicolon
          incomplete: ->(info) { $stderr.print('E'); errors << info } # rubocop:disable Style/Semicolon
        )
      end
      $stderr.print("\n")
    end

    # reporting
    report = CSV.generate(col_sep: ';') do |csv|
      errors.each do |id, title, old_addr, new_addr|
        csv << [name, id, title, old_addr, 'partial', *new_addr.values]
      end
      fails.each do |id, title, old_addr|
        csv << [name, id, title, old_addr, 'failed', nil, nil, nil, nil]
      end
    end
    write_report(report) if report.present?

    warn "#{name}: #{count}"
    warn "Errors: #{errors.size}"
    warn "Fails: #{fails.size}"
  end

  def erase_address(model)
    name = model.name.pluralize
    scope = with_address(model)
    count = scope.count

    warn "Deleting left-over Addresses of #{count} #{name}"
    scope.each do |contactable|
      contactable.address = nil
      contactable.save!
      $stderr.print('.')
    end
    $stderr.print("\n")
  end

  def write_report(content)
    @report << content
  end
end

class ReportMailer
  def initialize(report)
    @report = report
  end

  def send
    report = @report

    mail = Mail.new do
      from "migrations@#{ENV['RAILS_HOST_NAME'].split(':').first}"
      to Settings.root_email
      subject 'Migration to structured addresses'
      body 'Attached is the report about the migration.'
      add_file filename: 'report.csv', content: report
    end

    mail.delivery_method(
      (ENV['RAILS_MAIL_DELIVERY_METHOD'].presence || :smtp).to_sym,
      **YAML.load("{ #{ENV.fetch('RAILS_MAIL_DELIVERY_CONFIG', nil)} }").symbolize_keys
    )

    mail.deliver
  end
end

class SplitAddresses < ActiveRecord::Migration[6.1]
  def up
    splitter = Splitter.new(String.new.dup)
    splitter.split

    say_with_time 'Sending Report' do
      report = splitter.report

      say 'to STDOUT', true
      puts report

      say 'by mail', true
      ReportMailer.new(report).send
    end

    splitter.clean
  end

  def down
    # not entirely true, it would be reversible, I do not see the point
    raise ActiveRecord::IrreversibleMigration
  end
end
