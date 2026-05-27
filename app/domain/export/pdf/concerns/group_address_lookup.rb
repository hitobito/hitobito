#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::Concerns
  # Resolves a group's address with fallback to its layer group.
  # Returns the address parts as an array of strings (name, address, zip+town).
  # Including classes implement their own join logic.
  module GroupAddressLookup
    private

    def group_address_parts(group)
      resolved = resolve_group_with_address(group)
      return [] unless resolved

      [resolved.name.to_s.squish,
        resolved.address.to_s.squish,
        [resolved.zip_code, resolved.town].compact.join(" ").squish]
        .select(&:present?)
    end

    def resolve_group_with_address(group)
      return group if group_address_present?(group)
      group.layer_group if group_address_present?(group.layer_group)
    end

    def group_address_present?(group)
      return false unless group

      [:address, :town].all? { |a| group.send(a)&.strip.present? }
    end
  end
end
