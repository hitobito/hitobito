# frozen_string_literal: true

require 'test_helper'
class ServiceTest < ActiveSupport::TestCase
  def test_services_order_by_state_and_name
    ordered_services = Service.list.to_a

    # Show active services first
    expected_order = [
      services(:beratung),
      services(:software),
      services(:system),
      services(:kanalarbeiten)
    ]

    assert_equal expected_order, ordered_services
  end
end
