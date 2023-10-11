# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'simple_xlsx_reader'

module Import
  class XlsxReader
    def self.read(path, sheet_name, headers = {}, &block)
      workbook = SimpleXlsxReader.open path.to_s
      worksheet = workbook.sheets.select { |sheet| sheet.name == sheet_name }.first
      raise "No sheet named #{sheet_name} found." unless worksheet.present?
      if headers
        worksheet.rows.each(**headers, &block)
      else
        worksheet.rows.drop(1).each(&block)
      end
    end
  end
end
