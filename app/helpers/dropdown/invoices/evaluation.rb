# frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Dropdown
  class Invoices::Evaluation < Base

    attr_reader :params, :user

    def initialize(template, params, type)
      super(template, translate(type), type)
      @params = params
      @user = template.current_user
    end

    def export
      add_item(translate(:csv), export_path(:csv), **item_options)
      add_item(translate(:xlsx), export_path(:xlsx), **item_options)
      self
    end

    private

    def item_options
      { target: :new, data: { checkable: true } }
    end

    def export_path(format, options = {})
      params.merge(options).merge(format: format)
    end
  end
end
