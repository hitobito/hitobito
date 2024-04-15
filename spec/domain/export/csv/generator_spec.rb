# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require 'spec_helper'

describe Export::Csv::Generator do
  before { allow(Settings.csv).to receive(:utf8_bom).and_return(false) }

  let(:exportable) do
    double(labels: ['Header 1', 'Header 2']).tap do |e|
      allow(e).to receive(:data_rows).and_yield(['hello', 'world'])
    end
  end

  let(:data) { described_class.new(exportable).call }
  let(:bom_matcher) { Regexp.new("^#{Export::Csv::UTF8_BOM}") }
  let(:data_without_bom) { data.gsub(bom_matcher, '') }
  let(:csv) { CSV.parse(data_without_bom, col_sep: Settings.csv.separator) }

  describe 'encoding' do
    before do
      allow(exportable).to receive(:data_rows).and_yield(['hello', '😊'])
    end

    it 'converts to the configured encoding' do
      allow(Settings.csv).to receive(:encoding).and_return('ISO-8859-1')
      expect(data.encoding).to eq Encoding::ISO_8859_1
      expect(data).to eq "Header 1;Header 2\nhello;?\n".dup.force_encoding("ISO-8859-1")
    end

    it 'does not convert when no encoding is configured' do
      allow(Settings.csv).to receive(:encoding).and_return(nil)
      expect(data.encoding).to eq Encoding::UTF_8
    end

    it 'can be overridden with parameter' do
      data = described_class.new(exportable, encoding: 'ISO-8859-1').call
      expect(data.encoding).to eq Encoding::ISO_8859_1
    end

  end

  describe 'utf8 bom' do
    it 'adds the BOM header when configured' do
      allow(Settings.csv).to receive(:utf8_bom).and_return(true)
      expect(data).to match bom_matcher
    end

    it 'does not add the BOM header when not configured' do
      allow(Settings.csv).to receive(:utf8_bom).and_return(false)
      expect(data).not_to match bom_matcher
    end

    it 'can be overridden with parameter' do
      allow(Settings.csv).to receive(:utf8_bom).and_return(true)
      data = described_class.new(exportable, utf8_bom: false).call
      expect(data).not_to match bom_matcher
    end
  end

  describe 'separator' do
    it 'uses value from settings' do
      allow(Settings.csv).to receive(:separator).and_return('@')
      expect(data).to eq "Header 1@Header 2\nhello@world\n"
    end

    it 'can be overridden with parameter' do
      data = described_class.new(exportable, col_sep: '~').call
      expect(data).to eq "Header 1~Header 2\nhello~world\n"
    end
  end

  describe 'header row' do
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
