# frozen_string_literal: true

class ApplicationResource::RelationsBuilder
  delegate :has_many, :belongs_to, to: '@resource_class'
  delegate :reflect_on_all_associations, to: :model_class

  def initialize(resource_class, only: [], except: [])
    @resource_class = resource_class
    @only = only.collect(&:to_sym)
    @except = except.collect(&:to_sym)
  end

  def build
    each_assocation_with_resource do |relation, class_name|
      next if @except.include?(relation.name)
      next if @only.present? && @only.exclude?(relation.name)

      case relation
      when ActiveRecord::Reflection::HasManyReflection
        has_many relation.name, resource: class_name
      when ActiveRecord::Reflection::BelongsToReflection
        belongs_to relation.name, resource: class_name
      end
    end
  end

  def each_assocation_with_resource
    reflect_on_all_associations.each do |relation|
      class_name = "#{relation.class_name}Resource".safe_constantize

      yield relation, class_name if class_name
    end
  end

  def model_class
    @resource_class.model
  end
end
