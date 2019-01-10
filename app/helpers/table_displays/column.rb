# encoding: utf-8

#  Copyright (c) 2012-2019, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module TableDisplays
  class Column
    attr_reader :template, :table

    def initialize(template, name: nil, table: nil)
      @template = template
      @table = table
      @name = name
    end

    def label
      case template.parent
      when Group then Person.human_attribute_name(name)
      when Event then Event::Qualification.human_attribute_name(name)
      end
    end

    def render
      table.sortable_attr(name)
    end

    def name
      @name || self.class.to_s.demodulize.underscore
    end
  end
end
