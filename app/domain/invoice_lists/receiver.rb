# frozen_string_literal: true

#  Copyright (c) 2012-2025, Swiss Badminton. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module InvoiceLists
  Receiver = Data.define(:id, :layer_group_id) do
    def initialize(id:, layer_group_id: nil)
      super
    end

    def self.load(yaml)
      YAML.load(yaml).map do |row|
        case row
        in { id:, layer_group_id: } then new(id:, layer_group_id:)
        in Integer then new(id: row)
        end
      end
    end

    def self.dump(list)
      list.map do |row|
        row.is_a?(self) ? row.to_h : row
      end.to_yaml
    end
  end
end
