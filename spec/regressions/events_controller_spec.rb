require 'spec_helper'

describe EventsController, type: :controller do
  
  
  let(:test_entry) { Fabricate(:course, group: groups(:top_layer)) }
  let(:test_entry_attrs) { { name: 'Chief Leader Course' } }

  before { sign_in(people(:top_leader)) } 
  before { test_entry } # load test entry before tests to avoid some bugs

  include_examples 'crud controller', skip: [%w(index), %w(new), %w(create), %w(edit), %w(update), %w(destroy)]


end
