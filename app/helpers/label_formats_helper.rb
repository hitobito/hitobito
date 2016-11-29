# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module LabelFormatsHelper

  def label_formats_list_table(entries, *attrs)
    options = attrs.extract_options!
    add_css_class(options, 'table table-striped table-hover')
    # only use default attrs if no attrs and no block are given
    attributes = (block_given? || attrs.present?) ? attrs : default_attrs
    table(entries, options) do |t|
      t.sortable_attrs(*attributes)
      yield t if block_given?
    end
  end

  def label_formats_crud_table(entries, *attrs, &block)
    if block_given?
      label_formats_list_table(entries, *attrs, &block)
    else
      attrs = attrs_or_default(attrs) { default_attrs }
      label_formats_list_table(entries, *attrs) do |t|
        add_table_actions(t)
      end
    end
  end

  def format_landscape(format)
    t(:"label_formats.form.#{format.landscape ? :landscape : :portrait}")
  end

end
