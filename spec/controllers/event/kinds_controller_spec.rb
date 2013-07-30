# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Event::KindsController do
   
  let(:destroyed) { Event::Kind.with_deleted.find(ActiveRecord::Fixtures.identify(:old)) }
   
  before { sign_in(people(:top_leader)) }
   
  it "POST update resets destroy flag when updating deleted kinds" do
    destroyed.should be_destroyed
    post :update, id: destroyed.id
    destroyed.reload.should_not be_destroyed
  end
  
  it "GET index lists destroyed entries last" do
    get :index
    assigns(:kinds).last.should == destroyed
  end

  context "destroyed associations" do
    let(:old) { qualification_kinds(:old) }
    let(:kind) { event_kinds(:glk) } 

    context "GET new" do
      before { get :new } 

      it "does not include deleted for when creating new" do
        [:qualification_kinds, :preconditions, :prolongations].each do |list|
          assigns(list).should_not include old
        end
      end
    end

    context "GET edit" do
      before { kind.qualification_kinds << old }

      it "includes deleted qualification_kind where it has been selected" do
        get :edit, id: kind.id
        assigns(:qualification_kinds).should include old
        assigns(:preconditions).should_not include old
        assigns(:prolongations).should_not include old
      end
    end
  end

  
end
