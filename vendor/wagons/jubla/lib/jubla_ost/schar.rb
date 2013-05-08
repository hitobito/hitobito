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

    IGNORED = [71, 223, 244]

    class << self

      def migrate_state(current, legacy)
        migrate_groups(current, legacy, JublaOst::Schartyp::Kalei) {|g| Group::StateBoard }
        migrate_groups(current, legacy, JublaOst::Schartyp::Schar, *other_types) do |g|
          group_class(g.Schar, Group::StateProfessionalGroup, Group::StateWorkGroup)
        end
        # TODO delete default kalei
      end

      def migrate_region(current, legacy)
        migrate_releis(current, legacy)
        migrate_groups(current, legacy, JublaOst::Schartyp::Schar) {|g| Group::Flock }
        migrate_groups(current, legacy, *other_types) do |g|
          group_class(g.Schar, Group::RegionalProfessionalGroup, Group::RegionalWorkGroup)
        end
        # TODO delete default relei
      end

      private

      def other_types
        [JublaOst::Schartyp::Intern,
         JublaOst::Schartyp::Andere,
         JublaOst::Schartyp::Iast,
         JublaOst::Schartyp::Ehemalige]
      end

      def migrate_groups(parent, legacy, *types)
        flocks(legacy.REID, *types).each do |group|
          clazz = yield group
          migrate_group(parent, group, clazz)
        end
      end

      def flocks(region_id, *types)
        flocks = where('SCREID = ?', region_id)
        if types.present?
          flocks = flocks.where('st IN (?)', types.collect(&:id))
        end
        flocks
      end

      def group_class(name, fg_class, ag_class)
        case name
        when /^FG /, /^Fachgruppe / then fg_class
        when /^AG / then ag_class
        else Group::SimpleGroup
        end
      end

      def migrate_releis(parent, legacy)
        releis(legacy.REID).each do |group|
          migrate_group(parent, group, Group::RegionalBoard)
        end
      end

      def releis(region_id)
        joins('LEFT JOIN tmRegionRelei ON tmRegionRelei.ReleiSCID = tSchar.SCID').
        where('tmRegionRelei.RegID = ? AND tSchar.st = ?',
              region_id,
              JublaOst::Schartyp::Relei.id)
      end

      def migrate_group(parent, legacy_group, clazz)
        if legacy_group.Schar.present?
          group = clazz.new
          group.parent = parent
          migrate_attributes(group, legacy_group)
          group.save!
          cache[legacy_group.SCID] = group.id
          group
        end
      end

      def migrate_attributes(group, legacy)
        group.name = legacy.Schar
        group.short_name = legacy.Scharkurz
        group.zip_code = legacy.PLZ
        group.town = legacy.Ort
        group.email = legacy.SCemail
        group.address = combine("\n", legacy.Adresse1, legacy.Adresse2)
        if group.is_a?(Group::Flock)
          sanitize_name(group)
          migrate_flock_attributes(group, legacy)
        end
        if legacy.URL.present?
          group.social_accounts.build(label: 'Webseite', name: legacy.URL, public: true)
        end
        if legacy.erloschen.present?
          group.deleted_at = Time.zone.local(legacy.erloschen, 12, 31)
        end
      end

      def migrate_flock_attributes(group, legacy)
        group.kind = KINDS[legacy.Art]
        group.unsexed = legacy.geschlechtergemischt == '1'
        if legacy.Gemeinde.present?
          group.parish = "#{legacy.Pfarrei} (#{legacy.Gemeinde})"
        else
          group.parish = legacy.Pfarrei
        end
        group.jubla_insurance = legacy.Jublavers == 1
        group.jubla_full_coverage = legacy.Vollkasko == 1
        group.founding_year = legacy.gruendung
        group.clairongarde = legacy.clairon == 1
      end

      def sanitize_name(group)
        name = group.name
        name = strip_starting(name, 'Jungwacht ')
        name = strip_starting(name, 'Blauring ')
        name = strip_starting(name, 'Jubla ')
        group.name = name
      end

      def strip_starting(string, start)
        if string.downcase.starts_with?(start.downcase)
          string[start.size..-1]
        else
          string
        end
      end

    end

  end
end