module Export::Tabular::People
  class TableDisplays < PeopleAddress
    self.model_class = ::Person
    self.row_class = TableDisplayRow

    attr_reader :table_display

    def initialize(list, table_display)
      super(list)
      @table_display = table_display
    end

    def person_attributes
      [:first_name, :last_name, :nickname, :roles, :address, :zip_code, :town, :country]
    end

    def build_attribute_labels
      person_attribute_labels.merge(association_attributes).merge(selected_labels)
    end

    def selected_labels
      table_display.selected.each_with_object({}) do |attr, hash|
        hash[attr] = attribute_label(attr)
      end
    end

    def row_for(entry, format = nil)
      row_class.new(entry, table_display, format)
    end

  end
end
