#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Invoice::PaymentProcessJob < BaseJob
  self.parameters = [:data, :layer_group_id]

  def initialize(data, layer_group_id)
    super()
    @data = data
    @layer_group_id = layer_group_id
  end

  def perform
    Invoice::PaymentProcessor.new(@data, Group.find_by(id: @layer_group_id)).process
  end
end
