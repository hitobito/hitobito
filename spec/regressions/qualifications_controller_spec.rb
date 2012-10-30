# encoding:  utf-8

require 'spec_helper'

describe QualificationsController, type: :controller do

  let(:top_group) { groups(:top_group) }
  let(:top_leader) { people(:top_leader) }

  def scope_params
    { group_id: top_group.id, person_id: top_leader.id }
  end


  # Override a few methods to match the actual behavior.
  class << self
    def it_should_redirect_to_show
      it do
        should redirect_to group_person_path(top_group, top_leader)
      end 
    end
    
    def it_should_redirect_to_index
      it { should redirect_to group_person_path(top_group, top_leader) } 
    end
  end

  let(:test_entry) { @entry }
  let(:test_entry_attrs) { { start_at: 1.days.from_now.to_date, qualification_kind_id: qualification_kinds(:sl).id } }

  before do
    sign_in(people(:top_leader)) 
    @entry = Fabricate(:qualification, person: top_leader)
  end

  include_examples 'crud controller', skip: [%w(show), %w(edit), %w(index), %w(update)]

end
