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
      path = params.merge(format: :pdf)
      add_item(translate(:full), path)
      add_item(translate(:articles_only), path.merge(esr: false))
      add_item(translate(:esr_only), path.merge(articles: false))
    end
  end
end
