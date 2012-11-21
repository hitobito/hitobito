# encoding: UTF-8
require 'spec_helper'

describe Import::CsvParser do
  include CsvImportMacros
  let(:parser) { Import::CsvParser.new(data) } 
  before { parser.parse } 
  subject { parser } 

  [:utf8, :iso88591].each do |file| 
    describe "parse #{file}" do
      let(:data) { File.read(path(file)) } 
      its(:headers) { should eq ["Vorname", "Nachname", "Geburtsdatum"]  } 
      its([0]) { should eq CSV::Row.new(subject.headers, ["Ésaïe", "Gärber", "25.08.1992"]) } 
      its(:size) { should eq 1 } 
      its(:to_csv) { should eq "Vorname,Nachname,Geburtsdatum\nÉsaïe,Gärber,25.08.1992\n" } 
    end
  end


  context "empty file or nil file" do
    context "nil" do
      let(:data) { nil } 
      its(:error) { should eq "Enthält keine Daten" } 
    end

    context "blank" do
      let(:data) { "" } 
      its(:error) { should eq "Enthält keine Daten" } 
    end
  end

  context "two rows with empty field" do
    let(:data) { File.read(path(:two_rows)) } 
    its(:headers) { should eq ["Vorname", "Nachname", "Geburtsdatum", "Ort", "Email"]  } 
    its([1]) { should eq CSV::Row.new(subject.headers, ["Helin", "Fietz","","Bern","fietz.helin@jubla.example.com"]) } 
  end

  context "error when parsing" do
    let(:data) { File.read(path(:utf8, :ods)) } 
    its(:error) { should eq 'Unquoted fields do not allow \\r or \\n (line 2).' } 
  end

  context "mapping" do
    let(:data) { File.read(path(:utf8)) } 
    subject { OpenStruct.new(parser.map(header_mapping).first) } 

    context "complete" do
      let(:header_mapping) { { Vorname: 'first_name', Nachname: 'last_name', Geburtsdatum: 'birthday' } }
      its(:first_name) { should eq "Ésaïe" }
      its(:last_name) { should eq "Gärber" }
      its(:birthday) { should eq "25.08.1992" }
    end

    context "duplicate attribute" do
      let(:header_mapping) { { Vorname: 'first_name', Nachname: 'first_name', Geburtsdatum: 'birthday' } }
      its(:first_name) { should eq "Gärber" }
      its(:last_name) { should be_nil  }
      its(:birthday) { should eq "25.08.1992" }
    end

    context "empty attribute" do
      let(:header_mapping) { { Vorname: '', Nachname: 'last_name', Geburtsdatum: 'birthday' } }
      its(:first_name) { should be_nil }
      its(:last_name) { should eq "Gärber" }
      its(:birthday) { should eq "25.08.1992" }
    end

  end
end
