require 'spec_helper'
describe GroupsController, type: :controller  do
  include CrudControllerTestHelper
  render_views
 
  let(:asterix)  { groups(:asterix) }
  let(:flock) { groups(:bern) }
  let(:agency) { groups(:be_agency) }
  let(:region) { groups(:city) }
  let(:state) { groups(:be) }


  let(:leader) { Fabricate(Group::Flock::Leader.name.to_sym, group: flock).person }
  let(:agent) { Fabricate(Group::StateAgency::Leader.name.to_sym, group: groups(:be_agency)).person }
  let(:bulei) { Fabricate(Group::FederalBoard::Member.name.to_sym, group: groups(:federal_board)).person }

  let(:dom) { Capybara::Node::Simple.new(response.body) }

  let(:default_attrs) { { name: 'dummy' } }
  let(:mass_assignment_error) { ActiveModel::MassAssignmentSecurity::Error }

  describe_action :get, :edit, id: true do 
    expected = [
      [:leader, :flock, false],
      [:agent, :flock, true],
      [:agent, :region, true], 
      [:agent, :state, false]
    ]

    expected.each do |user, group, super_attr_present| 
      context "#{user} on #{group}" do
        before { sign_in(send(user)) }
        it " #{super_attr_present ? "can" : "cannot"} see superior_attributes" do
          get :edit, id: send(group).id
          matcher_for(super_attr_present) =~ /Jubla Versicherung/
        end
      end

    end

    def matcher_for(super_attr_present)
      super_attr_present ? :should : :should_not
    end
  end

  describe_action :get, :new do 
    expected = [
      [:leader, :asterix, true],
      [:leader, :flock, false],
      [:agent, :flock, true],
      [:agent, :region, true], 
      [:agent, :state, false]
    ]
    expected.each do |user, group, can_render_form| 
      context "#{user} new #{group}"  do
        before { sign_in(send(user)) }

        it "#{can_render_form ? "can" : "cannot"} render form" do
          get :new, group: { type: send(group).type, parent_id: send(group).parent.id } 
          if can_render_form
            dom.should have_selector('form[action="/groups"]')
          else
            response.should redirect_to root_url unless can_render_form
          end
        end
      end
    end
  end

  describe_action :put, :update, id: true do
    expected = [
      [:leader, :flock, true],
      [:leader, :flock, false, { jubla_insurance: '1' }],
      [:agent, :flock, true, { jubla_insurance: '1' }],
      [:agent, :region, true, { jubla_insurance: '1' } ], 
      [:agent, :state, true],
      [:agent, :state, false, {jubla_insurance: '1'}],
      [:bulei, :state, true, {jubla_insurance: '1'}],
    ]

    expected.each do |user, group, super_attr_update, extra_attrs={} | 
      context "#{user} on #{group}" do
        before { sign_in(send(user)) }
        it "#{super_attr_update ? "can" : "cannot"} update with #{extra_attrs}" do
          attrs = default_attrs.merge(extra_attrs)
          if super_attr_update
            put :update, id: send(group).id, group: attrs
            assigns(:group).name.should eq 'dummy'
          else
            expect { put :update, id: send(group).id, group: attrs }.to raise_error(mass_assignment_error)
          end
        end
      end
    end
  end


  describe_action :post, :create do 
    expected = [
      [:leader, :asterix, true],
      [:leader, :asterix, false, { jubla_insurance: '1'} ],
      [:leader, :flock, false],
      [:agent, :flock, true],
      [:agent, :region, true], 
      [:agent, :state, false]
    ]

    expected.each do |user, group, can_create_group, extra_attrs={}| 
      context "#{user} on #{group}"  do
        before { sign_in(send(user)) }

        it "#{can_create_group ? "can" : "cannot"} create group" do
          attrs = default_attrs.merge(type: send(group).type, parent_id: send(group).parent.id)
          attrs = attrs.merge(extra_attrs)
          if can_create_group
            expect { post :create, group: attrs }.to change(Group,:count).by(change_count(group))
            should redirect_to group_path(assigns(:group))
          else
            if extra_attrs.empty?
              expect { post :create, group: attrs }.not_to change(Group,:count) 
            else
              expect { post :create, group: attrs }.to raise_error(mass_assignment_error)
            end
          end
        end
      end
    end

    def change_count(group)
      (send(group).class.default_children.size + 1)
    end
  end


  describe_action :post, :destroy do 
    expected = [
      [:leader, :asterix, true],
      [:leader, :flock, false],
      [:agent, :flock, true],
      [:agent, :region, false], 
      [:agent, :state, false]
    ]

    expected.each do |user, group, can_destroy_group| 
      context "#{user} destroy #{group}"  do
        before { sign_in(send(user)) }

        it "#{can_destroy_group ? "can" : "cannot"} destroy group" do
          if can_destroy_group
            expect { post :destroy, id: send(group).id }.to change { Group.without_deleted.count }.by(change_count(group))
          else
            expect { post :create, id: send(group).id }.not_to change(Group,:count)
          end
        end
      end
    end
    def change_count(group)
      (send(group).children.size + 1) * -1
    end
  end

end
