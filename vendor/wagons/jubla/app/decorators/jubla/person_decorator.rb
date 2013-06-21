module Jubla::PersonDecorator
  extend ActiveSupport::Concern

  def active_roles_grouped
    roles_array.reject(&:alumnus?).each_with_object(Hash.new {|h,k| h[k] = []}) do |role, memo|
      memo[role.group] << role
    end
  end

  def alumni_roles_grouped
    roles_array.select(&:alumnus?).each_with_object(Hash.new {|h,k| h[k] = []}) do |role, memo|
      memo[role.group] << role
    end
  end

  private

  def roles_array
    @roles_array ||= roles.to_a
  end
  
end
