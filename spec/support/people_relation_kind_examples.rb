#  Copyright (c) 2014, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# A set of examples that validate the people relation kind definitions.
shared_examples "people relation kinds" do |options|
  context ".kind_opposites" do
    it "contains all keys and values" do
      hash = PeopleRelation.kind_opposites
      expect(hash.keys).to match_array(hash.values)
    end

    it "contains only strings" do
      hash = PeopleRelation.kind_opposites
      expect(hash.values.collect(&:to_s)).to eq(hash.values)
    end
  end

  context ".possible_kinds" do
    it "are all translated" do
      PeopleRelation.possible_kinds.each do |kind|
        expect(PeopleRelation.new(kind: kind).translated_kind).not_to eq(kind)
      end
    end
  end
end
