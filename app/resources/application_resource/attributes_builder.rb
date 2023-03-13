# frozen_string_literal: true

class ApplicationResource::AttributesBuilder
  delegate :attribute, to: '@resource_class'
  delegate :columns, to: '@resource_class.model'

  def initialize(resource_class, only: [], except: [], writables: [], **opts)
    @resource_class = resource_class
    @except = except.collect(&:to_s)
    @only = only.collect(&:to_s)
    @writables = writables
    @opts = opts || {}
  end

  def build
    columns.each do |column|
      next if column.name == 'id'
      next if @except.include?(column.name)
      next if @only.present? && @only.exclude?(column.name)

      attribute column.name.to_sym, *details(column)
    end
  end

  def details(column)
    type, config = case column.type
                   when :text then :string
                   when :decimal then :float
                   when :enum then [
                     :string_enum,
                     allow: enum_values(column.sql_type_metadata.sql_type)
                   ]
                   else column.type
    end
    options = @opts.merge(with_nullable(column, config || {}))
    options[:writable] = @writables.include?(column.name.to_sym)

    [type, options]
  end

  def with_nullable(column, config)
    config.merge(nullable: column.null)
  end

  def enum_values(enum_type)
    ActiveRecord::Base.connection.enum_types.fetch(enum_type.to_sym)
  end
end
