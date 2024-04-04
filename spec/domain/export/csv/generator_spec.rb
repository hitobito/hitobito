# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require 'spec_helper'

describe Export::Csv::Generator do
  let(:data) { described_class.new(exportable).call }
  let(:data_without_bom) { data.gsub(Regexp.new("^#{Export::Csv::UTF8_BOM}"), '') }
  let(:csv) { CSV.parse(data_without_bom, col_sep: Settings.csv.separator) }

  let(:exportable) do
    double(labels: ['Header 1', 'Header 2']).tap do |e|
      allow(e).to receive(:data_rows).and_yield(['hello', 'world'])
    end
  end

  context 'header row' do
    it 'with labels adds the header rows' do
      expect(csv).to have(2).items
      expect(csv.first).to eq ['Header 1', 'Header 2']
    end

    it 'without labels does not add a header row' do
      allow(exportable).to receive(:labels).and_return(nil)
      expect(csv).to have(1).items
      expect(csv.first).to eq ['hello', 'world']
    end
  end
end
