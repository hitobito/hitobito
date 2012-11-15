# encoding: UTF-8
require 'spec_helper'

describe Import::CsvParser do
  include CsvImportMacros
  let(:parser) { Import::CsvParser.new(data) } 
  before { parser.parse } 
  subject { parser } 

  [:utf8, :iso88591, :utf8_with_spaces][0..1].each do |file| 
    describe "parse  #{file}" do
      let(:data) { File.read(path(file)) } 
      its(:headers) { should eq ["Vorname", "Nachname", "Geburtsdatum"]  } 
      its(:first) { should eq CSV::Row.new(subject.headers, ["Ésaïe", "Gärber", "25.08.1992"]) } 
      its(:size) { should eq 1 } 
      its(:to_csv) { should eq "Vorname,Nachname,Geburtsdatum\nÉsaïe,Gärber,25.08.1992\n" } 
    end
  end

  context "error when parsing" do
    let(:data) { File.read(path(:utf8, :ods)) } 
    its(:error) { should eq 'Unquoted fields do not allow \\r or \\n (line 2).' } 
  end

  context "merge" do
    let(:data) { File.read(path(:utf8)) } 

    context "complete mapping" do
      subject { OpenStruct.new(parser.map_headers(mapping).first) } 
      let(:mapping) { { Vorname: 'first_name', Nachname: 'last_name', Geburtsdatum: 'birthday' } }
      its(:first_name) { should eq "Ésaïe" }
      its(:last_name) { should eq "Gärber" }
      its(:birthday) { should eq "25.08.1992" }
    end

    context "duplicate mapping" do
      subject { OpenStruct.new(parser.map_headers(mapping).first) } 
      let(:mapping) { { Vorname: 'first_name', Nachname: 'first_name', Geburtsdatum: 'birthday' } }
      its(:first_name) { should eq "Gärber" }
      its(:last_name) { should be_nil  }
      its(:birthday) { should eq "25.08.1992" }
    end
  end
end
