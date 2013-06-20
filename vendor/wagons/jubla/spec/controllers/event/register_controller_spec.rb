require 'spec_helper'

describe Event::RegisterController do
  
  let(:event) { Fabricate(:event, groups: [groups(:be_board)], external_applications: true) }
  let(:group) { event.groups.first }
  
  describe 'PUT register' do
    it "creates external role" do
      expect do
        put :register, group_id: group.id, id: event.id, person: {last_name: 'foo', email: 'foo@example.com'}
      end.to change { Group::StateBoard::External.where(group_id: group.id).count }.by(1)
    end
  end
end
