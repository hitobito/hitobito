#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# ActionCable dispatches broadcasts via thread pools, so the browser in feature specs
# could receive successive updates of the same record in arbitrary order.
ActionCable::SubscriptionAdapter::Test.prepend(Module.new do
  private

  def new_subscriber_map
    ActionCable::SubscriptionAdapter::SubscriberMap.new
  end
end)

ActionCable.server.config.worker_pool_size = 1
