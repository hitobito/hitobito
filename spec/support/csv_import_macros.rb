module CsvImportMacros

  FILES = [:utf8, :iso88591, :utf8_with_spaces]

  def path(name, extension=:csv)
    File.expand_path("../csv/#{name}.#{extension}", __FILE__)
  end
  def default_mapping
    { Vorname: 'first_name', Nachname: 'last_name', Geburtsdatum: 'birthday' }
  end

end
