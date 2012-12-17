# encoding: utf-8
module Sheet
  class CsvImport < Base
    self.parent_sheet = Sheet::Group
    
    def title
      'Personen über CSV importieren'
    end
  end
end