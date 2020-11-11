# encoding: utf-8
# frozen_string_literal: true

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Dropdown
  class InvoiceSending < Base

    attr_reader :params, :path, :invoice_list_id

    def initialize(template, params)
      super(template, translate(:button), :envelope)
      @params      = params
      @invoice_list_id = template.invoice_list&.id
      init_items
    end

    private

    def init_items
      send_links
    end

    def send_links
      add_item(:set_state, mail: false, invoice_list_id: invoice_list_id)
      add_item(:send_mail, mail: true, invoice_list_id: invoice_list_id)
    end

    def add_item(key, options = {})
      path = template.group_invoice_list_path(template.parent, options)
      super(translate(key), path, data: { method: :put, checkable: true })
    end

  end
end
