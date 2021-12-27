# frozen_string_literal: true

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Import::CsvParser do
  include CsvImportMacros
  let(:parser) { Import::CsvParser.new(data) }
  before { parser.parse }
  subject { parser }

  [:utf8, :iso88591].each do |file|
    describe "parse #{file}" do
      let(:data) { File.read(path(file)) }
      its(:headers) { should eq %w(Vorname Nachname Geburtsdatum)  }
      its([0]) { should eq CSV::Row.new(subject.headers, ['Ésaïe', 'Gärber', '25.08.1992']) }
      its(:size) { should eq 1 }
      its(:to_csv) { should eq "Vorname,Nachname,Geburtsdatum\nÉsaïe,Gärber,25.08.1992\n" }
    end
  end

  context 'blank lines' do
    let(:data) { File.read(path(:blank_lines)) }
    its(:size) { should eq 2 }
    its(:to_csv) do
      should eq "Vorname,Nachname,Geburtsdatum\nÉsaïe,Gärber,25.08.1992\nFoo,Bar,25.08.1992\n"
    end
  end

  context 'empty lines' do
    let(:data) { File.read(path(:empty_lines)) }
    its(:size) { should eq 2 }
    its(:to_csv) do
      should eq "Vorname,Nachname,Geburtsdatum\nÉsaïe,Gärber,25.08.1992\nFoo,Bar,25.08.1992\n"
    end
  end

  context 'fields with blanks' do
    let(:data) { File.read(path(:fields_with_blanks)) }
    its(:size) { should eq 1 }
    its(:to_csv) do
      should eq "Vorname dump,Nachname tralal,Geburtsdatum\nÉsaïe foo,Gärber bla,25.08.1992\n"
    end
  end

  context 'empty file or nil file' do
    context 'nil' do
      let(:data) { nil }
      its(:error) { should eq 'Enthält keine Daten' }
    end

    context 'blank' do
      let(:data) { '' }
      its(:error) { should eq 'Enthält keine Daten' }
    end
  end

  context 'two rows with empty field' do
    let(:data) { File.read(path(:two_rows)) }
    its(:headers) { should eq %w(Vorname Nachname Geburtsdatum Ort Email) }
    its([1]) do
      should eq CSV::Row.new(subject.headers,
                             ['Helin', 'Fietz', '', 'Bern', 'fietz.helin@hitobito.example.com'])
    end
  end

  context 'empty header' do
    let(:data) { File.read(path(:empty_header)) }
    its('csv.headers') { should eq ['first', '', 'last'] }
    its(:headers) { should eq %w(first last) }
    its([0]) { should eq CSV::Row.new(subject.csv.headers, ['foo', nil, 'bar']) }
    its([1]) { should eq CSV::Row.new(subject.csv.headers, [nil, 'foobar', nil]) }

  end

  context 'error when parsing' do
    let(:data) { File.read(path(:utf8, :ods)) }
    its(:error) { should eq 'Unquoted fields do not allow \\r or \\n (line 2).' }
  end

  context 'mapping rows' do
    let(:data) { File.read(path(:utf8)) }
    subject { OpenStruct.new(parser.map_data(header_mapping).first) }

    context 'complete' do
      let(:header_mapping) do
        { Vorname: 'first_name', Nachname: 'last_name', Geburtsdatum: 'birthday' }
      end
      its(:first_name) { should eq 'Ésaïe' }
      its(:last_name) { should eq 'Gärber' }
      its(:birthday) { should eq '25.08.1992' }
    end

    context 'duplicate attribute' do
      let(:header_mapping) do
        { Vorname: 'first_name', Nachname: 'first_name', Geburtsdatum: 'birthday' }
      end
      its(:first_name) { should eq 'Gärber' }
      its(:last_name) { should be_nil }
      its(:birthday) { should eq '25.08.1992' }
    end

    context 'empty attribute' do
      let(:header_mapping) { { Vorname: '', Nachname: 'last_name', Geburtsdatum: 'birthday' } }
      its(:first_name) { should be_nil }
      its(:last_name) { should eq 'Gärber' }
      its(:birthday) { should eq '25.08.1992' }
    end

    context 'empty and whitespaced attributes' do
      let(:data) { File.read(path(:list)) }
      let(:parser) { Import::CsvParser.new(File.read(path(:list))) }
      let(:header_mapping) { headers_mapping(parser) }
      subject { parser.map_data(header_mapping) }


      its([3]) do
        should eq 'first_name' => 'Athäna',
                  'last_name' => 'Rippin',
                  'company' => '1',
                  'company_name' => 'Holly Stamm MD',
                  'email' => 'athena_rippin@example.com',
                  'address' => nil,
                  'zip_code' => '34-6726',
                  'town' => nil,
                  'country' => 'Schweiz',
                  'gender' => nil,
                  'birthday' => nil,
                  'phone_number_andere' => nil,
                  'phone_number_arbeit' => '+41 44 123 45 67',
                  'phone_number_fax' => '+41 32 109 87 65',
                  'phone_number_mobil' => '0800 123 333',
                  'phone_number_mutter' => '+49 345 592055912',
                  'phone_number_privat' => '077 901 23 45',
                  'phone_number_vater' => '+49 6334 39335476',
                  'social_account_skype' => 'dale_walter',
                  'social_account_msn' => 'christina.reilly',
                  'social_account_webseite' => 'bosco.com',
                  'additional_information' =>
                    'Qui repellendus quas quibusdam reprehenderit. '\
                    'Qui mollitia quo molestias debitis adipisci nostrum sed. '\
                    'Rerum ut cumque ut impedit neque et laboriosam.',
                  'tags' => 'bar,baz'
      end
    end

  end
end
