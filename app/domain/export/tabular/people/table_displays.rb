module Export::Tabular::People
  class TableDisplays < PeopleAddress
    self.model_class = ::Person
    self.row_class = PersonRow

    attr_reader :table_display

    def initialize(list, table_display)
      super(list)
      @table_display = table_display
    end

    def person_attributes
      [:first_name, :last_name, :nickname, :roles, :address, :zip_code, :town, :country] +
        table_display.selected
    end

  end
end
