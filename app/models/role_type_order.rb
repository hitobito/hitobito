#  Copyright (c) 2014, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: role_type_orders
#
#  id           :bigint           not null, primary key
#  name         :string
#  order_weight :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class RoleTypeOrder < ActiveRecord::Base
end
