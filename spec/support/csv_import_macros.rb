# frozen_string_literal: true

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module CsvImportMacros

  FILES = [:utf8, :iso88591, :utf8_with_spaces].freeze

  def path(name, extension = :csv)
    Rails.root.join('spec', 'fixtures', 'csv', "#{name}.#{extension}")
  end

  def default_mapping
    { Vorname: 'first_name', Nachname: 'last_name', Geburtsdatum: 'birthday' }
  end

  def headers_mapping(parser)
    parser.headers.each_with_object({}) { |header, hash| hash[header] = header }
  end

  def generate_csv(*args)
    CSV.generate { |csv| args.each { |arg| csv << arg } }
  end

end
