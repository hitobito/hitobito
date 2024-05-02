#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Export::Tabular::People::PeopleFull do

  before do
    PeopleRelation.kind_opposites['parent'] = 'child'
    PeopleRelation.kind_opposites['child'] = 'parent'
  end

  after do
    PeopleRelation.kind_opposites.clear
  end

  let(:person) { people(:top_leader) }
  let(:list) { [person] }
  let(:people_list) { Export::Tabular::People::PeopleFull.new(list) }

  subject { people_list }

  its(:attributes) do
    expected = [
      :first_name, :last_name, :company_name, :nickname, :company, :email,
      :zip_code, :town, :country, :gender, :birthday, :additional_information, :language,
      :street, :housenumber, :address_care_of, :postbox, :layer_group, :roles, :tags
    ]

    should match_array expected
    should eq expected
  end

  context '#attribute_labels' do
    subject { people_list.attribute_labels }

    its([:roles]) { should eq 'Rollen' }
    its([:social_account_website]) { should be_blank }

    its([:company]) { should eq 'Firma' }
    its([:company_name]) { should eq 'Firmenname' }

    context 'social accounts' do
      before { person.social_accounts << SocialAccount.new(label: 'Webseite', name: 'foo.bar') }
      its([:social_account_webseite]) { should eq 'Social Media Adresse Webseite' }
    end

    context 'people relations' do
      before do
        person.relations_to_tails << PeopleRelation.new(head_id: person.id,
                                                        tail_id: people(:bottom_member).id, kind: 'parent')
      end
      its([:people_relation_parent]) { should eq 'Elternteil' }
    end
  end

end
