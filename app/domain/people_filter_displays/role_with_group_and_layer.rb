module PeopleFilterDisplays
  RoleWithGroupAndLayer = Data.define(:role_types) do
    def options
      role_types.flat_map do |layer, hash|
        hash.flat_map { |g, role_types|
          role_types.map { |r|
            [[layer, g, r.label].uniq.join(" -> "), r.id, r.id]
          }
        }
      end
    end
  end
end
