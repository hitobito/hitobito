class UpdateLanguageFilterAttrsToAttributeFilterAttrs < ActiveRecord::Migration[7.1]
  def up
    # Filter all entries with a defined filter chain
    records = entries_with_defined_filter_chain(MailingList) + entries_with_defined_filter_chain(PeopleFilter)
    records.each do |record|
      begin
        # Find language filter if exists otherwise skip to next filter chain
        language_filter = find_filter_attr("language", record.filter_chain)
        next unless language_filter

        # Prepare new entry of language values in attributes
        timestamp = (Time.now.to_f * 1000).to_i.to_s
        new_entry = {
          "key" => "language",
          "constraint" => "equal",
          "value" => language_filter.allowed_values
        }

        # Add to attributes filter or create new one
        attributes_filter = find_filter_attr("attributes", record.filter_chain)
        if attributes_filter
          attributes_filter.args[timestamp] = new_entry
        else
          filter = Person::Filter::Attributes.new("attributes", {timestamp => new_entry})
          record.filter_chain.filters << filter
        end

        # Remove original language filter and save modified recod
        record.filter_chain.filters.reject! { |filter_attribute| filter_attribute.instance_variable_get(:@attr) == "language" }
        unless record.save
          migration.say("UpdateLanguageFilterAttrsToAttributeFilterAttrs: Error saving filter #{record}")
        end
      rescue => e
        migration.say("UpdateLanguageFilterAttrsToAttributeFilterAttrs: Error converting filter #{record} #{e.message}")
      end
    end
  end

  private

  def entries_with_defined_filter_chain(entry)
    entry.select { |r| r.filter_chain.filters.any? }
  end

  def find_filter_attr(attr, chain)
    chain.filters.find do |filter|
      filter.instance_variable_get(:@attr) == attr
    end
  end
end
