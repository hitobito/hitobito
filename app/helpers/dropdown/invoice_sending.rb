# encoding: utf-8
# frozen_string_literal: true

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Dropdown
  class InvoiceSending < Base

    attr_reader :params

    def initialize(template, params, path_method)
      super(template, translate(:button), :envelope)
      @params      = params
      @path_method = path_method
      init_items
    end

    private

    def init_items
      send_links
    end

    def send_links
      add_item(:set_state, mail: false)
      add_item(:send_mail, mail: true)
    end

    def add_item(key, options = {})
      path = @template.send(@path_method, options)
      super(translate(key), path, data: { method: :put, checkable: true })
    end

  end
end
