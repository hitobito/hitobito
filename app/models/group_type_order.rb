# == Schema Information
#
# Table name: group_type_orders
#
#  id           :bigint           not null, primary key
#  name         :string
#  order_weight :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class GroupTypeOrder < ActiveRecord::Base
end
