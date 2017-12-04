# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Dropdown
  class InvoicesExport < Base

    attr_reader :params

    def initialize(template, params)
      super(template, translate(:button), :download)
      @params = params
      init_items
    end

    private

    def init_items
      pdf_links
      label_links
    end

    def pdf_links
      add_item(:full)
      add_item(:articles_only, esr: false)
      add_item(:esr_only, articles: false)
    end

    def add_item(key, options = {})
      path = params.merge(options).merge(format: :pdf)
      super(translate(key), path.merge(options), data: { invoice_export: true })
    end

    def label_links
      if LabelFormat.exists?
        label_item = add_item(:labels, main_label_link)
        add_last_used_format_item(label_item)
        add_label_format_items(label_item)
      end
    end

    def add_last_used_format_item(parent)
      if user.last_label_format_id?
        last_format = user.last_label_format
        parent.sub_items << Item.new(last_format.to_s,
                                     export_label_format_path(last_format.id),
                                     data: { invoice_export: true },
                                     target: :new)
        parent.sub_items << Divider.new
      end
    end

    def add_label_format_items(parent)
      LabelFormat.list.for_person(user).each do |label_format|
        parent.sub_items << Item.new(label_format, export_label_format_path(label_format.id),
                                     data: { invoice_export: true },
                                     target: :new, class: 'export-label-format')
      end
    end

    def export_label_format_path(id)
      params.merge(format: :pdf, label_format_id: id)
    end

    def main_label_link
      if user.last_label_format_id
        export_label_format_path(user.last_label_format_id)
      else
        '#'
      end
    end

    def user
      template.current_user
    end

  end
end
