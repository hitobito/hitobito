# encoding: utf-8
# == Schema Information
#
# Table name: qualification_kinds
#
#  id             :integer          not null, primary key
#  validity       :integer
#  created_at     :datetime
#  updated_at     :datetime
#  deleted_at     :datetime
#  reactivateable :integer
#

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
Fabricator(:qualification_kind) do
  label { Faker::Company.bs }
  validity { 2 }
end
