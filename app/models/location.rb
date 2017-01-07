# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito_pbs and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

# == Schema Information
#
# Table name: locations
#
#  id       :integer          not null, primary key
#  name     :string           not null
#  canton   :string(2)        not null
#  zip_code :string           not null
#

class Location < ActiveRecord::Base

  validates_by_schema
  validates :name, uniqueness: { scope: [:zip_code, :canton] }
  validates :canton, inclusion: { in: Cantons.short_name_strings }

  def canton_label
    Cantons.full_name(canton)
  end

end
