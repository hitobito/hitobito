# encoding: utf-8

#  Copyright (c) 2012-2015, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe 'export import person' do

  let(:group) { groups(:top_group) }
  let(:role_type) { Group::TopGroup::Leader }

  it 'may import what is exported' do
    exported = Fabricate(:person,
                         first_name: 'Foo',
                         last_name: 'Exporter',
                         company_name: 'Puzzle',
                         company: false,
                         nickname: 'Expo',
                         email: 'exporter@hitobito.example.org',
                         address: 'Foostreet',
                         zip_code: 'A1234',
                         town: 'Berlin',
                         country: 'DE',
                         gender: 'm',
                         birthday: Date.new(1980, 5, 1),
                         additional_information: "bla bla bla\nbla bla")

    Fabricate(:phone_number, contactable: exported, label: 'Privat')
    Fabricate(:phone_number, contactable: exported, label: 'Mobil')
    Fabricate(:additional_email, contactable: exported)
    Fabricate(:social_account, contactable: exported, label: 'Webseite')

    csv = export(exported)

    # change to not get a duplicate match
    exported.update!(last_name: 'Exported', email: 'exported@hitobito.example.org')

    import(csv)

    imported = Person.find_by_email('exporter@hitobito.example.org')
    expect(imported).not_to eq(exported)

    excluded = %w(id created_at updated_at primary_group_id contact_data_visible email last_name)
    expect_attrs_equal(imported, exported, excluded)

    %w(phone_numbers social_accounts additional_emails).each do |assoc|
      expect(imported.send(assoc).size).to eq(exported.send(assoc).to_a.size)
      exported.send(assoc).each_with_index do |e, i|
        expect_attrs_equal(imported.send(assoc)[i], e, %w(id contactable_id))
      end
    end
  end

  def export(person)
    Export::Tabular::People::PeopleFull.csv([person])
  end

  def import(csv)
    parser = Import::CsvParser.new(csv)
    parser.parse

    guesser = Import::PersonColumnGuesser.new(parser.headers)
    header_mapping = guesser.mapping.each_with_object({}) do |map, hash|
      hash[map.first] = map.last[:key]
    end

    data = parser.map_data(header_mapping)
    importer = Import::PersonImporter.new(data, group, role_type)
    importer.user_ability = Ability.new(people(:top_leader))
    importer.import
  end

  def expect_attrs_equal(actual, expected, excluded)
    expect(actual.attributes.except(*excluded)).to eq(expected.attributes.except(*excluded))
  end

end
