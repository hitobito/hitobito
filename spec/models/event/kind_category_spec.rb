# == Schema Information
#
# Table name: event_kind_categories
#
#  id         :bigint           not null, primary key
#  deleted_at :datetime
#  label      :string
#  order      :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require "spec_helper"

describe Event::KindCategory do
  let!(:abk) { Fabricate(:event_kind_category, {order: 3, label: "Aufbaukurse"}) }
  let!(:bsk) { Fabricate(:event_kind_category, {order: 2, label: "Basiskurse"}) }
  let!(:afk) { Fabricate(:event_kind_category, {order: 1, label: "Auffrischungskurse"}) }

  it "orders categories by order column" do
    expect(Event::KindCategory.pluck(:order).to_a).to eq [1, 2, 3]
  end

  it "handles nil as order" do
    bsk.update!(order: nil)
    expect(Event::KindCategory.pluck(:order).to_a).to eq [nil, 1, 3]
  end
end
