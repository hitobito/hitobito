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

  end
end
