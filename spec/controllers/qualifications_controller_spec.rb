require 'spec_helper'
describe QualificationsController do

  before { sign_in(person) }
  let(:group) { groups(:top_group) }
  let(:person) { people(:top_leader) }
  let(:params) { { group_id: group.id, person_id: person.id } }
  


  context "GET new" do
    it "builds entry for person" do
      get :new, params
      qualification = assigns(:qualification)
      qualification.person.should eq person
    end
  end


  context "POST create" do
    let(:kind) { qualification_kinds(:gl)}
    it "redirects to show for person" do
      expect { 
        post :create, params.merge(qualification: { qualification_kind_id: kind.id, start_at: Time.zone.now }) 
        should redirect_to group_person_path(group, person)
      }.to change { Qualification.count }.by (1)
    end

    it "fails without permission" do
      sign_in(people(:bottom_member))
      expect { 
        post :create, params.merge(qualification: { qualification_kind_id: kind.id, start_at: Time.zone.now }) 
      }.not_to change { Qualification.count }.by (1)
    end
  end

  context "POST destroy" do
    let(:id) { @qualification.id }
    before { @qualification = Fabricate(:qualification, person: person)}
    it "redirects to show for person" do
      expect { 
        post :destroy, params.merge(id: id) 
        should redirect_to group_person_path(group, person)
      }.to change { Qualification.count }.by (-1)
    end

    it "fails without permission" do
      sign_in(people(:bottom_member))
      expect { 
        post :destroy, params.merge(id: id) 
      }.not_to change { Qualification.count }.by (-1)
    end
  end
  
  
  
end

