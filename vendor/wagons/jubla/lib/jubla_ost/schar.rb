module JublaOst
  # Scharen, Releis, Kaleis, AGs, FGs, ...
  class Schar < Base
    self.table_name = 'tSchar'
    self.primary_key = 'SCID'

    # Kaleis werden nicht importiert
    # Releis werden via RegionRelei der ersten Region zugeordnet, welche nicht einem Kanton entspricht.
    # Scharen werden via SCREID der Region zugeordent
    # Alle anderen Typen werden via SCREID der Region/Kanton zugeordnet. Startet der Name mit AG/FG, wird
    # eine Arbeitsgruppe/Fachgruppe erstellt, sonst eine einfache Gruppe.

    KINDS = {'br' => 'Blauring',
             'jw' => 'Jungwacht',
             'jubla' => 'Jubla'}

    class << self
      def migrate_state(current, legacy)
        migrate_others(current, legacy, Group::StateProfessionalGroup, Group::StateWorkGroup)
      end

      def migrate_region(current, legacy)
        #TODO flocks(legacy.REID, JublaOst::Schartyp::Relei)

        migrate_others(current, legacy, Group::RegionalProfessionalGroup, Group::RegionalWorkGroup)
        flocks(legacy.REID, JublaOst::Schartyp::Schar).each do |group|
          migrate_group(current, group, Group::Flock)
        end
      end

      def flocks(region_id, *types)
        flocks = where('SCREID = ?', region_id)
        if types.present?
          flocks = flocks.where('st IN (?)', types.collect(&:id))
        end
        flocks
      end

      private

      def migrate_others(current, legacy, fg_class, ag_class)
        flocks(legacy.REID, JublaOst::Schartyp::Intern,
                            JublaOst::Schartyp::Andere,
                            JublaOst::Schartyp::Iast,
                            JublaOst::Schartyp::Ehemalige).each do |group|
          clazz = group_clazz(group.Schar, fg_class, ag_class)
          migrate_group(current, group, clazz)
        end
      end

      def group_class(name, fg_class, ag_class)
        case name
        when /^FG /, /^Fachgruppe / then fg_class
        when /^AG / then ag_class
        else Group::SimpleGroup
        end
      end

      def migrate_group(parent, legacy_group, clazz)
        group = clazz.new
        group.parent = parent
        migrate_attributes(group, legacy_group)
        group.save!
        group
      end

      def migrate_attributes(group, legacy)
        group.name = legacy.Schar
        group.short_name = legacy.Scharkurz
        group.zip_code = legacy.PLZ
        group.town = legacy.Ort
        group.email = legacy.SCemail
        group.address = [legacy.Adresse1, legacy.Adresse2].compact.join("\n")
        # TODO: bank_account
        if group.is_a?(Group::Flock)
          group.kind = KINDS[legacy.Art]
          group.unsexed = legacy.geschlechtergemischt == '1'
          group.parish = legacy.Pfarrei
          group.jubla_insurance = legacy.Jublavers
          group.jubla_full_coverage = legacy.Vollkasko
          group.founding_year = legacy.gruendung
          group.clairongarde = legacy.clairon
        end
        if legacy.URL.present?
          group.social_accounts.build(label: 'Webseite', name: legacy.URL, public: true)
        end
      end

    end

  end
end