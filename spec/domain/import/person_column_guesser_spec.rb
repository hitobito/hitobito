require 'spec_helper'
describe  Import::PersonColumnGuesser do

  let(:headers) { ['Geschlecht', 'vorname', 'Name', 'skype'] }
  let(:guesser) { Import::PersonColumnGuesser.new(headers) }

  context "maps default values for header" do
    subject { guesser.mapping }

    its(['Geschlecht']) { should eq field_for(:gender) }
    its(['vorname']) { should eq field_for(:first_name) }
    its(['skype']) { should eq field_for(:social_account_skype) }

    context "maps first occurance from Import::Person.fields" do
      its(['Name']) { should eq field_for(:company_name) }
    end

    context "handles noexisting headers" do
      let(:headers) { ["asdf" ] }
      its(['asdf']) { should eq Hash.new(key:nil) }
    end
  end


  def field_for(key)
    field = Import::Person.fields.find { |f| f[:key] == key.to_s }
    raise "no Person field found for #{key}" if !field
    field
  end

end
