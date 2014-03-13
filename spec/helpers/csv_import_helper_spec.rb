require 'spec_helper'

describe CsvImportHelper do
  context '#csv_field_documentation' do
    it 'renders string directly' do
      csv_field_documentation(:first_name, 'Only nice names').should
        eq '<dt>Vorname</dt><dd>Only nice names</dd>'
    end

    it 'renders hashes as options' do
      csv_field_documentation(:gender, 'w' => 'Girls', 'm' => 'Gents').should
        eq '<dt>Geschlecht</dt><dd><em>w</em> - Girls<br/><em>m</em> - Gents</dd>'
    end
  end
end
