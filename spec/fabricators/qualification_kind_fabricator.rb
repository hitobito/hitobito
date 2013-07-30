# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: qualification_kinds
#
#  id             :integer          not null, primary key
#  label          :string(255)      not null
#  validity       :integer
#  description    :string(1023)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  deleted_at     :datetime
#  reactivateable :integer
#

Fabricator(:qualification_kind) do
  label { Faker::Company.bs }
  validity { 2 }
end
