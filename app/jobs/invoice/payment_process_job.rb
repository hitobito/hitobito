#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Invoice::PaymentProcessJob < BaseJob
  self.parameters = [:data]

  def initialize(data)
    super()
    @data = data
  end

  def perform
    Invoice::PaymentProcessor.new(@data).process
  end
end
