# frozen_string_literal: true

require Rails.root.join("db", "seeds", "support", "event_seeder")

srand(42)

seeder = EventSeeder.new

layer_types = Group.all_types.select(&:layer).collect(&:sti_name)
Group.where(type: layer_types).pluck(:id).each do |group_id|
  5.times do
    seeder.seed_event(group_id, :base)
  end
end
