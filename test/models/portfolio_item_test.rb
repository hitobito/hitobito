# frozen_string_literal: true

require 'test_helper'
class PortfolioItemTest < ActiveSupport::TestCase
  def test_portfolio_items_order_by_state_and_name
    ordered_portfolio_items = PortfolioItem.list.to_a

    # Show active portfolio items first
    expected_order = [
      portfolio_items(:mobile),
      portfolio_items(:web),
      portfolio_items(:iaas)
    ]

    assert_equal expected_order, ordered_portfolio_items
  end
end
