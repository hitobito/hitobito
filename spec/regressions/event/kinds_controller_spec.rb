# encoding:  utf-8

require 'spec_helper'

describe Event::KindsController, type: :controller do

  class << self
    def it_should_redirect_to_show
      it { should redirect_to event_kinds_path } 
    end
  end

  let(:test_entry) { event_kinds(:slk) }
  let(:test_entry_attrs) { { label: 'Automatic Bar Course', 
                             short_name: 'ABC',
                             minimum_age: 21,
                             qualification_kind_ids: [qualification_kinds(:sl).id],
                             prolongation_ids: [qualification_kinds(:gl).id] } }

  before { sign_in(people(:top_leader)) } 

  include_examples 'crud controller', skip: [%w(show), %w(destroy)]

  it "soft deletes" do
    expect { post :destroy, id: test_entry.id }.to change { Event::Kind.without_deleted.count }.by(-1) 
  end

end
