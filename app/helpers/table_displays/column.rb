#  Copyright (c) 2012-2018, Schweizer Blasmusikverband. This file is part of
#  hitobito_sbv and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module TableDisplays
  class Column
    attr_reader :template, :table, :model_class, :ability

    def initialize(ability, model_class:, table: nil)
      @ability = ability
      @model_class = model_class
      @table = table
      @template = table&.template
    end

    # Allows a column class to specify which database columns need to be fetched for calculating the
    # value
    def required_model_attrs(attr)
      raise 'implement in subclass'
    end

    def value_for(object, attr)
      raise 'implement in subclass, using `super do ... end`' unless block_given?

      target, target_attr = resolve(object, attr)
      if target.present? && target_attr.present? && allowed?(target, target_attr)
        yield target, target_attr
      end
    end

    def label(attr)
      model_class.human_attribute_name(attr)
    end

    # The column class may specify how to sort, by returning a SQL string. Default nil means the
    # column is not sortable.
    def sort_by(attr)
      nil
    end

    def render(attr)
      table.col(header(attr)) { |object| value_for(object, attr) }
    end

    def header(attr)
      if sort_by(attr).present?
        table.sort_header(attr, label(attr))
      else
        label(attr)
      end
    end

    protected

    def required_permission(attr)
      raise 'implement in subclass'
    end

    def allowed?(object, attr)
      ability.can? required_permission(attr), object
    end

    # Recursively resolve nested attrs
    def resolve(object, path)
      return object, path unless path.include? '.'

      relation, relation_path = path.to_s.split('.', 2)
      resolve(object.try(relation), relation_path)
    end
  end
end
