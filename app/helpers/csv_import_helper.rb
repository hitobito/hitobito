# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module CsvImportHelper

  def fields
    Import::Person.fields.map { |field| OpenStruct.new(field) }
  end

  def possible_roles
    @group.possible_roles.map { |role| OpenStruct.new(role) }
  end
end
