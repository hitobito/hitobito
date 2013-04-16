module JublaOst
  class PersonFunktion < Base
    self.table_name = 'tmPersFunkt'
    self.primary_key = 'PEFUid'

    class << self

      def migrate_person_roles(current, legacy)
        person_schars = find_person_schars(legacy.PEID)
        unhandled_schars = person_schars.keys

        # create roles for all tmPersFunkt
        where(PEID: legacy.PEID).each do |person_funktion|
          scid = person_funktion.SCID
          create_role(current, scid, person_schars[scid], Funktion.all[person_funktion.FUID])
          unhandled_schars.delete(scid)
        end

        # create roles for all tmPersSchar without tmPersFunkt
        unhandled_schars.each do |scid|
          create_role(current, scid, person_schars[scid], nil)
        end
      end

      private

      def find_person_schars(peid)
        PersonSchar.where(PEID: peid).where('SCID IS NOT NULL').each_with_object({}) do |entry, memo|
          memo[entry.SCID] = entry
        end
      end

      def create_role(current, scid, person_schar, funktion)
        if group_id = Schar.cache[scid]
          group = Group.find(group_id)
          role = build_role(group, funktion)
          assign_attributes(role, current, group, person_schar)
          role.save!
        else
          puts "No Schar with id=#{scid} found while migrating roles of #{current.to_s}"
        end
      end

      def build_role(group, funktion)
          role_class = Funktion::Mappings[group.class][funktion]
          if role_class.nil?
            Funktion::Mappings[group.class][nil].new(label: funktion.label)
          else
            role_class.new
          end
      end

      def assign_attributes(role, current, group, person_schar)
        role.person = current
        role.group = group
        # TODO set präses attributes
        if person_schar
          role.created_at = person_schar.Eintritt
          if person_schar.Austritt
            role.deleted_at = person_schar.Austritt
            create_alumnus_role(role)
          end
        end
        role.created_at ||= Time.zone.now
        role.updated_at = role.created_at
      end

      def create_alumnus_role(role)
        unless role.person.roles.where(type: Jubla::Role::Alumnus.sti_name).exists?
          alumnus = Jubla::Role::Alumnus.new
          alumnus.person = role.person
          alumnus.group = role.group
          alumnus.created_at = alumnus.updated_at = role.deleted_at
          alumnus.label = role.class.label
          alumnus.save!
        end
      end
    end
  end
end