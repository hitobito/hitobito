# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: locations
#
#  id       :integer          not null, primary key
#  canton   :string(2)        not null
#  name     :string(255)      not null
#  zip_code :string(255)      not null
#
# Indexes
#
#  index_locations_on_zip_code_and_canton_and_name  (zip_code,canton,name) UNIQUE
#

class Location < ActiveRecord::Base
  validates_by_schema
  validates :name, uniqueness: {scope: [:zip_code, :canton], case_sensitive: true}
  validates :canton, inclusion: {in: Cantons.short_name_strings}

  def canton_label
    Cantons.full_name(canton)
  end
end
