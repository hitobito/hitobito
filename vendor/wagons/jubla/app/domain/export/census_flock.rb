require 'csv'
require 'ostruct'

module Export
  class CensusFlock < Struct.new(:year)

    attr_reader :items

    class << self
      def headers
        { name: human(:name),
          contact_first_name: "Kontakt Vorname",
          contact_last_name: "Kontakt Nachname",
          address: human(:address),
          zip_code: human(:zip_code),
          town: human(:town) ,
          jubla_insurance: human(:jubla_insurance),
          jubla_full_coverage: human(:jubla_full_coverage),
          leader_count: "Leiter",
          child_count: "Kinder" }
      end

      def labels
        headers.values
      end

      private

      def human(attr)
        Group::Flock.human_attribute_name(attr)
      end
    end

    def items
      @items ||= build_items
    end

    def to_csv
      @csv = CSV.generate(options) do |csv|
        csv << self.class.headers.values
        items.each do |item|
          csv << item.values
        end
      end
    end

    private

    def build_items
      member_counts = build_member_counts

      query_flocks.map do |flock|
        build_item(flock, member_counts[flock.id])
      end
    end

    def build_member_counts
      query_member_counts.each_with_object(Hash.new(null_member_count)) do |item, hash|
        hash[item.flock_id] = item
      end
    end

    def query_flocks
      ::Group::Flock.includes(:contact).order('groups.name')
    end

    def query_member_counts
      ::MemberCount.totals(year).group(:flock_id)
    end

    def build_item(flock, member_count)
      { name: flock.name,
        contact_first_name: flock.contact ? flock.contact.first_name : nil,
        contact_last_name: flock.contact ? flock.contact.last_name : nil,
        address: flock.address,
        zip_code: flock.zip_code,
        town: flock.town,
        jubla_insurance: flock.jubla_insurance,
        jubla_full_coverage: flock.jubla_full_coverage,
        leader_count: member_count.leader,
        child_count: member_count.child }
    end

    def null_member_count
      OpenStruct.new(leader: nil, child: nil)
    end


    def options
      { col_sep: Settings.csv.separator.strip }
    end

  end
end
