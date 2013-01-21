require 'spec_helper'

describe Event::RegisterController do
  
  let(:event) { events(:top_event) }
  let(:group) { event.groups.first }
  
  context "GET index" do
    
    context "application possible" do
      before do
        event.update_column(:application_opening_at, 5.days.ago)
      end
      
      context "as logged in user" do
        before { sign_in(people(:top_leader)) }
        it "displays event page" do
          get :index, group_id: group.id, id: event.id
          should redirect_to(group_event_path(group, event))
        end
      end
      
      context "as external user" do
        it "displays external login forms" do
          get :index, group_id: group.id, id: event.id
          should render_template('index')
          flash[:notice].should be_present
        end
      end
    end
    
    context "application not possible" do
      before do
        event.update_attribute(:application_opening_at, 5.days.from_now)
      end
      
      context "as logged in user" do
        before { sign_in(people(:top_leader)) }
        it "displays event page" do
          get :index, group_id: group.id, id: event.id
          should redirect_to(group_event_path(group, event))
          flash[:alert].should be_present
        end
      end
      
      context "as external user" do
        it "displays standard login forms" do
          get :index, group_id: group.id, id: event.id
          should redirect_to(new_person_session_path)
          flash[:alert].should be_present
        end
      end
    end
  end
  
  context "POST check" do
    context "without email" do
      it "displays form again" do
        post :check, group_id: group.id, id: event.id, person: { email: ''}
        should render_template('index')
        flash[:alert].should be_present
      end
    end
    
    context "with honeypot filled" do
      it "redirects to login" do
        post :check, group_id: group.id, id: event.id, person: { email: 'foo@example.com'}, name: 'Foo'
        should redirect_to(new_person_session_path)
      end
    end
    
    context "for existing person" do
      it "generates one time login token" do
        post :check, group_id: group.id, id: event.id, person: {email: people(:top_leader).email }
        should render_template('index')
        people(:top_leader).reload.reset_password_token.should be_present
        flash[:notice].should be_present
      end
    end
    
    context "for non-existing person" do
      it "displays person form" do
        post :check, group_id: group.id, id: event.id, person: {email: 'not-existing@example.com' }
        should render_template('register')
        flash[:notice].should be_present
      end
    end
  end
  
  context "PUT register" do
    context "with valid data" do
      it "creates person" do
        expect do
          put :register, group_id: group.id, id: event.id, person: {last_name: 'foo', email: 'not-existing@example.com' }
        end.to change { Person.count }.by(1)
        
        should redirect_to(group_event_path(group, event))
        flash[:notice].should be_present
      end
    end
    
    context "with honeypot filled" do
      it "redirects to login" do
        put :register, group_id: group.id, id: event.id, person: { last_name: 'foo', email: 'foo@example.com'}, name: 'Foo'
        should redirect_to(new_person_session_path)
      end
    end
    
    context "with invalid data" do
      it "does not create person" do
        expect do
          put :register, group_id: group.id, id: event.id, person: {email: 'not-existing@example.com' }
        end.not_to change { Person.count }
        
        should render_template('register')
      end
    end
  end
  
end
