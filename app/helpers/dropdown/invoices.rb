# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Dropdown
  class Invoices < Base

    attr_reader :params, :user

    def initialize(template, params, type)
      super(template, translate(type), type)
      @params = params
      @user = template.current_user
    end

    def print
      pdf_links
      self
    end

    def export
      label_links
      self
    end

    private

    def pdf_links
      add_item(translate(:full), export_path, item_options)
      add_item(translate(:articles_only), export_path(esr: false), item_options)
      add_item(translate(:esr_only), export_path(articles: false), item_options)
    end

    def label_links
      if LabelFormat.exists?
        Dropdown::LabelItems.new(self, item_options.merge(condense_labels: false)).add
      end
    end

    def item_options
      { target: :new, data: { checkable: true } }
    end

    def export_path(options = {})
      params.merge(options).merge(format: :pdf)
    end

  end
end
