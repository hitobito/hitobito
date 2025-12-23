# frozen_string_literal: true

#  Copyright (c) 2012-2025, Swiss Badminton. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module InvoiceRuns
  Receiver = Data.define(:id, :type, :layer_group_id) do
    def initialize(id:, type:, layer_group_id: nil)
      super
      ensure_valid_type
    end

    def self.load(yaml)
      YAML.load(yaml).map do |row|
        case row
        in { id:, type:, layer_group_id: } then new(id:, type:, layer_group_id:)
        # TODO The following typeless variants can be removed starting mid 2026
        in { id:, layer_group_id: } then new(id:, type: "Person", layer_group_id:)
        in Integer then new(id: row, type: "Person")
        in String then new(id: Integer(row), type: "Person")
        end
      end
    end

    def self.dump(list)
      list.map do |row|
        row.is_a?(self) ? row.to_h : row
      end.to_yaml
    end

    private

    def ensure_valid_type
      clazz = type.to_s.safe_constantize or raise ArgumentError, "Unknown type #{type.inspect}"
      return if clazz < Contactable

      raise ArgumentError, "Invalid type #{type.inspect}, must be a Contactable"
    end
  end
end
