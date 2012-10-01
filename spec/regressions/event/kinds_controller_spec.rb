# encoding:  utf-8

require 'spec_helper'

describe Event::KindsController, type: :controller do

  class << self
    def it_should_redirect_to_show
      it { should redirect_to event_kinds_path } 
    end
  end

  let(:test_entry) { event_kinds(:slk) }
  let(:test_entry_attrs) { { label: 'Automatic Bar Course', short_name: 'ABC' } }

  before { sign_in(people(:top_leader)) } 

  include_examples 'crud controller', skip: [%w(show)]

  it { respond_to?(:setup_db).should == false }
end
