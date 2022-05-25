#  Copyright (c) 2012-2022, Schweizer Blasmusikverband. This file is part of
#  hitobito_sbv and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::People
  class TableDisplayRow < PersonRow
    attr_reader :table_display, :answers

    def initialize(entry, table_display, format = nil)
      @table_display = table_display
      super(entry, format)
    end

    def login_status
      status = entry.login_status
      I18n.t("people.login_status.#{status}")
    end

    private

    def value_for(attr)
      column = table_display.column_for(attr)
      unless column.present?
        if entry.respond_to?(attr) || dynamic_attribute?(attr.to_s)
          return super
        end
        return nil
      end

      column.value_for(column_entry, attr) do |target, target_attr|
        if respond_to?(target_attr, true)
          send(target_attr)
        elsif target.respond_to?(target_attr)
          target.public_send(target_attr)
        end
      end
    end

    def column_entry
      entry
    end

  end
end
