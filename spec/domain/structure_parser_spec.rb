# frozen_string_literal: true

#  Copyright (c) 2023-2023, Jungschar EMK. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.


# load rails and dependencies, basically to widen the LOAD_PATH and have zeitgeist
ENV['RAILS_ENV'] = 'test'
require File.expand_path('../../config/environment', __dir__)

# load system under test
require 'structure_parser'

describe StructureParser do
  let(:structure) do
    <<~TEXT
      * Dachverband
          * Dachverband
              * Administrator/-in: [:admin, :layer_and_below_full, :impersonation]
          * Vorstand
              * Präsident/-in: [:layer_read, :group_and_below_full, :contact_data]
              * Kassier/-in: [:layer_and_below_read, :finance, :contact_data]
              * Mitglied:  [:layer_read, :contact_data]
          * Geschäftsstelle
              * Geschäftsleiter/-in: [:admin, :layer_and_below_full, :impersonation, :contact_data]
              * Angestellte/-r: [:admin, :layer_and_below_full, :impersonation, :contact_data]
          * Gremium
              * Leiter/-in: [:layer_read, :group_and_below_full, :contact_data]
              * Kassier/-in: [:layer_read, :finance]
              * Mitglied: [:layer_read]
          * Mitglieder
              * Adressverwalter/-in: [:group_and_below_full]
              * Mitglied: []
      * Region
          * Region
              * Administrator/-in: [:layer_and_below_full]
          * Vorstand
              * Präsident/-in: [:layer_and_below_read, :group_and_below_full, :contact_data]
              * Kassier/-in: [:layer_and_below_read, :finance, :contact_data]
              * Mitglied: [:layer_and_below_read, :contact_data]
          * Geschäftsstelle
              * Geschäftsleiter/-in: [:layer_and_below_full, :finance, :contact_data]
              * Angestellte/-r: [:layer_and_below_full, :finance, :contact_data]
          * Gremium
              * Leiter/-in: [:layer_and_below_read, :group_and_below_full, :contact_data]
              * Kassier/-in: [:layer_and_below_read, :finance]
              * Mitglied: [:group_and_below_read]
          * Mitglieder
              * Adressverwalter/-in: [:group_and_below_full]
              * Mitglied: []
      * Lagerverein
          * Lagerverein
              * Administrator/-in: [:layer_and_below_full]
          * Verein
              * Leiter/-in: [:layer_read, :group_and_below_full, :contact_data]
              * Kassier/-in: [:layer_read, :finance]
              * Mitglied: [:layer_read]
      * Ortsjungschar
          * Ortsjungschar
              * Hauptleitung: [:layer_and_below_full, :contact_data]
              * Leiter/-in: [:group_and_below_full, :contact_data]
              * Adressverwaltung: [:group_and_below_full, :contact_data]
              * Coach: [:layer_and_below_full, :approve_applications, :contact_data]
              * Kassier: [:layer_read, :finance]
              * Materialverantwortliche/-r: [:layer_and_below_read, :contact_data]
              * Aktivmitglied: [:group_and_below_read]
              * Passivmitglied: []
          * Vorstand
              * Präsident/-in: [:layer_full, :contact_data]
              * Sekretär/-in: [:layer_full, :contact_data]
              * Vorstandsmitglied: [:layer_full, :contact_data]
          * Gremium/Projektgruppe
              * Leiter/-in: [:group_and_below_full, :contact_data]
              * Mitglied: [:group_and_below_read]
          * Mitglieder
              * Leiter/-in: [:group_and_below_full, :contact_data]
              * Aktivmitglied: [:group_and_below_read]
              * Passivmitglied: []
    TEXT
  end

  it 'can be created' do
    described_class.new(structure)
  end

  it 'can parse a structure' do
    described_class.new(structure, common_indent: 0, shiftwidth: 4).parse
  end

  context 'has a result after simple "first pass"-parsing, which' do
    subject do
      described_class.new(
        structure.lines.take(3).join("\n"),
        common_indent: 0,
        shiftwidth: 4
      )
    end
    before(:each) { subject.first_pass }

    it 'can be read' do
      expect(subject.result).to_not be_nil
    end

    it do
      expect(subject.result).to be_a Hash
    end

    it 'has the expected structure' do
      expect(subject.result.inspect).to eql({
        'Layer Dachverband with 1 subgroup(s)' => {
          'Group Dachverband with 1 role(s)' => [
            'Role Administrator/-in with [:admin, :layer_and_below_full, :impersonation]'
          ]
        }
      }.inspect)
    end
  end

  context 'has a result after simple "two pass"-parsing' do
    subject do
      described_class.new(
        structure.lines.take(17).join("\n"),
        common_indent: 0,
        shiftwidth: 4
      )
    end

    before(:each) do
      subject.first_pass
      subject.second_pass
    end

    it 'can be read' do
      expect(subject.result).to_not be_nil
    end

    it do
      expect(subject.result).to be_an Array
    end

    it 'has the expected first level structure' do
      expect(subject.result.first.to_s)
        .to eql 'LayerGroup Dachverband with 4 subgroup(s) and 1 role(s)'
    end

    it 'has the expected first level structure' do
      actual = subject.result.map(&:to_s)
      expected = [
        'LayerGroup Dachverband with 4 subgroup(s) and 1 role(s)',
        'Group DachverbandVorstand with 0 subgroup(s) and 3 role(s)',
        'Group DachverbandGeschäftsstelle with 0 subgroup(s) and 2 role(s)',
        'Group DachverbandGremium with 0 subgroup(s) and 3 role(s)',
        'Group DachverbandMitglieder with 0 subgroup(s) and 2 role(s)'
      ]
      expect(actual).to match_array(expected)
      expect(actual).to eql(expected)
    end
  end

  context 'has a result after complete parsing, it' do
    subject do
      described_class.new(
        structure,
        common_indent: 0,
        shiftwidth: 4
      )
    end

    before(:each) do
      subject.parse
    end

    it 'can be read' do
      expect(subject.result).to_not be_nil
    end

    it do
      expect(subject.result).to be_an Array
    end

    it 'has the expected first level structure' do
      expect(subject.result.first.to_s)
        .to eql 'LayerGroup Dachverband with 4 subgroup(s) and 1 role(s)'
    end

    it 'has the expected roles on a certain group' do
      # rubocop:disable Layout/LineLength
      expect(subject.result[1].roles.map(&:to_s)).to match_array [
        'Role Präsident/-in with [:layer_read, :group_and_below_full, :contact_data] in group DachverbandVorstand',
        'Role Kassier/-in with [:layer_and_below_read, :finance, :contact_data] in group DachverbandVorstand',
        'Role Mitglied with [:layer_read, :contact_data] in group DachverbandVorstand'
      ]
      # rubocop:enable Layout/LineLength
    end

    it 'has the expected structure' do
      actual = subject.result.map(&:to_s)
      expected = [
        'LayerGroup Dachverband with 4 subgroup(s) and 1 role(s)',
        'Group DachverbandVorstand with 0 subgroup(s) and 3 role(s)',
        'Group DachverbandGeschäftsstelle with 0 subgroup(s) and 2 role(s)',
        'Group DachverbandGremium with 0 subgroup(s) and 3 role(s)',
        'Group DachverbandMitglieder with 0 subgroup(s) and 2 role(s)',
        'LayerGroup Region with 4 subgroup(s) and 1 role(s)',
        'Group RegionVorstand with 0 subgroup(s) and 3 role(s)',
        'Group RegionGeschäftsstelle with 0 subgroup(s) and 2 role(s)',
        'Group RegionGremium with 0 subgroup(s) and 3 role(s)',
        'Group RegionMitglieder with 0 subgroup(s) and 2 role(s)',
        'LayerGroup Lagerverein with 1 subgroup(s) and 1 role(s)',
        'Group LagervereinVerein with 0 subgroup(s) and 3 role(s)',
        'LayerGroup Ortsjungschar with 3 subgroup(s) and 8 role(s)',
        'Group OrtsjungscharVorstand with 0 subgroup(s) and 3 role(s)',
        'Group OrtsjungscharGremium/Projektgruppe with 0 subgroup(s) and 2 role(s)',
        'Group OrtsjungscharMitglieder with 0 subgroup(s) and 3 role(s)'
      ]
      expect(actual).to match_array(expected)
      expect(actual).to eql(expected)
    end
  end

  context 'has assumptions' do
    subject { described_class.new(structure) }

    it 'can parse a line' do
      input = <<~TEXT
        * Dachverband
      TEXT

      line = input.lines.first
      expect(line.delete_prefix('').chomp).to eql '* Dachverband'
    end

    it 'can extract a layer-name' do
      /^\* (.*)$/ === '* Dachverband' # actually emulate case # rubocop:disable Lint/Void,Style/CaseEquality
      expect(Regexp.last_match(1)).to eql 'Dachverband'
    end
  end
end
