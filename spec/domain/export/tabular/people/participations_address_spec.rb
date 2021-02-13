#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Tabular::People::ParticipationsAddress do
  let(:person) { people(:top_leader) }
  let(:participation) { Fabricate(:event_participation, person: person, event: events(:top_course)) }
  let(:list) { [participation] }
  let(:people_list) { Export::Tabular::People::ParticipationsAddress.new(list) }

  subject { people_list.attribute_labels }

  context "address data" do
    its([:first_name]) { is_expected.to eq "Vorname" }
    its([:town]) { is_expected.to eq "Ort" }
  end
end
