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
