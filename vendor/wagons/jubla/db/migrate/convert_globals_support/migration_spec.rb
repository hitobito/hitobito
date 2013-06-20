$LOAD_PATH << File.expand_path('../', __FILE__)
require 'rspec'
require 'rspec/autorun'
require 'rspec/expectations'

require 'base'
require 'migrator'

describe "Migration" do

  let(:roles)  { [Jubla::Role::GroupAdmin,
                  Jubla::Role::DispatchAddress,
                  Jubla::Role::Alumnus,
                  Jubla::Role::External] }


  it "verify_filters" do
    filters = load_filters.each_with_object({}) { |filter, memo| memo[filter] = filtered_people(filter).to_a }
    with_rollback do
      filters.each { |filter, people| filtered_people(filter).size.should eq people.size }
    end
  end

  it "verify_lists" do
    lists = load_mailing_lists.each_with_object({}) { |list, memo| memo[list] = list.people.to_a }
    with_rollback do
      lists.each do |list, people|
        if list.people.count != people.size
        end
        list.reload.people.count.should eq people.size
      end
    end
  end

  def with_rollback
    ActiveRecord::Base.transaction do
      roles.each { |role| Migrator.new(role).perform }
      yield
      raise ActiveRecord::Rollback
    end
  end

  def load_mailing_lists
    roles.map do |role_type|
      Subscription
        .joins(:related_role_types)
        .where(subscriber_type: 'Group')
        .where(related_role_types: { role_type: role_type})
    end.flatten.map(&:mailing_list)
  end

  def load_filters
    roles.map do |role_type|
      PeopleFilter
        .joins(:related_role_types)
        .where(related_role_types: { role_type: role_type})
    end.flatten.uniq
  end

  def filtered_people(filter)
    Person.in_or_below(filter.group)
      .where(roles: {type: filter.reload.related_role_types.map(&:role_type)})
  end
  
end
