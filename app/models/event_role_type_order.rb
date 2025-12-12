# == Schema Information
#
# Table name: event_role_type_orders
#
#  id           :bigint           not null, primary key
#  name         :string
#  order_weight :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class EventRoleTypeOrder < ActiveRecord::Base
end
