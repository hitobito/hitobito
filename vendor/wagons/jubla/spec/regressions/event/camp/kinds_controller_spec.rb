# encoding:  utf-8

require 'spec_helper'
#require_relative '../../../../app/controllers/event/camp/kinds_controller.rb'

describe Event::Camp::KindsController, type: :controller do

  class << self
    def it_should_redirect_to_show
      it { should redirect_to event_camp_kinds_path } 
    end
  end

  let(:test_entry) { Event::Camp::Kind.first }
  let(:test_entry_attrs) { { label: 'Automatic Bar Course' }}

  before { sign_in(people(:top_leader)) } 

  include_examples 'crud controller', skip: [%w(show)]

end
