# encoding: utf-8

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.
#
# == Schema Information
#
# Table name: addresses
#
#  id       :bigint           not null, primary key
#  street   :string(255)      not null
#  town     :string(255)      not null
#  zip_code :integer          not null
#  state    :string(255)      not null
#  numbers  :text(65535)
#

class Address < ActiveRecord::Base
  serialize :numbers, Array

  validates_by_schema

  scope :list, -> { order(:street, "LENGTH(numbers) DESC") }

end
