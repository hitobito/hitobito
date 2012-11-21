# encoding: UTF-8
require 'spec_helper'
describe Import::PersonImporter do

  let(:group) { groups(:top_group) } 
  let(:role_type) { "Group::TopGroup::Leader" }
  let(:importer)  { Import::PersonImporter.new(group: group, role_type: role_type, data: data)  } 
  subject { importer } 

  context "minimal" do
    let(:data) { [ {first_name: 'foo'} ] }

    it "creates person" do
      expect { subject.import }.to change(Person,:count).by(1)
    end

    it "creates role" do
      expect { subject.import }.to change(Role,:count).by(1)
    end
  end

  context "creates associations" do
    let(:data) { [ {first_name: 'foo', social_account_skype: 'foobar', phone_number_vater: '0123' } ] }

    it "creates person" do
      expect { subject.import }.to change(SocialAccount,:count).by(1)
    end

    it "creates role" do
      expect { subject.import }.to change(PhoneNumber,:count).by(1)
    end
  end

  context "records successfull and failed imports" do
    let(:data) { [ {first_name: 'foobar', email: 'foo@bar.net' },  {first_name: 'foobar', email: 'foo@bar.net' }] }

    it "creates only first record" do
      expect { subject.import }.to change(Person,:count).by(1)
    end

    context "result" do
      before { importer.import } 
      its(:success_count)  { should eq 1 }
      its(:failure_count)  { should eq 1 }
    end

    context "base error" do
      let(:data) { [ {} ] }
      before { importer.import } 
      its('errors.first') { should eq "Zeile 1: Bitte geben Sie einen Namen für diese Person ein" }
    end

    context "email validation" do
      before { importer.import } 
      its('errors.first') { should eq "Zeile 2: Email ist bereits vergeben" }
    end
  end

end



