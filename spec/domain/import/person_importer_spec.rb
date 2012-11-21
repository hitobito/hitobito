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

  context "records successful and failed imports" do
    let(:data) { [ {first_name: 'foobar', email: 'foo@bar.net' },  {first_name: 'foobar', zip_code: 'asdf' }] }

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

    context "zip_code validation" do
      before { importer.import } 
      its('errors.first') { should eq "Zeile 2: PLZ ist keine Zahl" }
    end
  end

  context "doublettes" do
    let(:attrs) { {first_name: 'foobar', email: 'foo@bar.net' } }
    let(:data) { [attrs.merge(email: 'bar@foo.net')] }
    let(:person) { @person.reload }

    before { @person = Fabricate(:person, attrs) }
    subject { person } 


    context "adds role, does not update email" do
      before { importer.import } 
      its(:email) { should eq 'foo@bar.net' } 
      its('roles.size') { should eq 1 }
      it "updates double and success count" do
        importer.doublette_count.should eq 1
        importer.success_count.should eq 0
      end
    end

    context "does not duplicate role" do
      before do
        role = person.roles.new
        role.group = group
        role.type = role_type
        role.save
        importer.import 
        person.reload
      end
      its(:email) { should eq 'foo@bar.net' } 
      its('roles.size') { should eq 1 }
    end

    context "marks multiple" do
      before { Fabricate(:person, attrs.merge(email: 'asdf@asdf.net')); importer.import }
      subject { importer } 
      its(:errors) { should eq ['Zeile 1: 2 Treffer in Duplikatserkennung.'] }
    end
  end

end



