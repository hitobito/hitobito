module CsvImportHelper

  def fields
    Import::Person.fields.map {|field| OpenStruct.new(field) } 
  end

  def possible_roles
    @group.possible_roles.map {|role| OpenStruct.new(role) } 
  end
end
