#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe PaperTrail::Version, versioning: true do
  it "verifies all paper_trailed models have item_label lambda" do
    ActiveRecord::Base.descendants.select { _1.respond_to?(:paper_trail_options) }.each do |model_class|
      expect(model_class.paper_trail_options[:meta][:item_label]).to be_a(Proc)
    end
  end

  it "safes item_label to version" do
    people(:top_leader).update!(first_name: "Foo")
    expect(PaperTrail::Version.last.item_label).to eq "Foo Leader"
  end
end
