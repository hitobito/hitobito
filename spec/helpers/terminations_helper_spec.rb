# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require 'spec_helper'

describe TerminationsHelper do
  let(:role) { roles(:bottom_member) }
  subject(:termination) { Roles::Termination.new(role: role) }

  it '#termination_main_person_text' do
    expect(helper.termination_main_person_text(termination)).to match /#{role.person.full_name}/
  end

  it '#termination_affected_people_text mentions all affected_people' do
    allow(termination).to receive(:affected_people).
      and_return(people(:top_leader, :bottom_member))

    people(:top_leader, :bottom_member).each do |person|
      expect(helper.termination_affected_people_text(termination)).to include person.full_name
    end
  end
end
