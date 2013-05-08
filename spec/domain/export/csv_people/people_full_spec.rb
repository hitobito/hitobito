require 'spec_helper'

describe Export::CsvPeople::PeopleFull do

  let(:person) { people(:top_leader) }
  let(:list) { [person] }
  let(:people_list) { Export::CsvPeople::PeopleFull.new(list) }
  subject { people_list }

  its([:roles]) { should eq 'Rollen' }
  its(:attributes) { should eq [:first_name, :last_name, :company_name, :nickname, :company, :email, :address,
                                :zip_code, :town, :country, :gender, :birthday, :additional_information] }

  its([:social_account_website]) { should be_blank }

  its([:company]) { should eq 'Firma' }
  its([:company_name]) { should eq 'Firmenname' }

  context "social accounts" do
    before { person.social_accounts << SocialAccount.new(label: 'Webseite', name: 'foo.bar') }
    its([:social_account_webseite]) { should eq 'Social Media Adresse Webseite' }
  end
end
