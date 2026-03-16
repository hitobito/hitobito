# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe PaperTrail::VersionDecorator, :draper_with_helpers, versioning: true do
  include Rails.application.routes.url_helpers

  let(:person) { people(:top_leader) }
  let(:version) { PaperTrail::Version.where(main_id: person.id).order(:created_at, :id).last }
  let(:decorator) { PaperTrail::VersionDecorator.new(version) }

  before { PaperTrail.request.whodunnit = nil }

  context "#header" do
    subject { decorator.header }

    context "without current user" do
      before { update }

      it { is_expected.to match(/^\w+, \d+\. [\w|ä]+ \d{4}, \d{2}:\d{2} Uhr$/) }
    end

    context "with current user" do
      before do
        PaperTrail.request.whodunnit = person.id.to_s
        update
      end

      it do
        is_expected.to match(
          /^\w+, \d+\. [\w|ä]+ \d{4}, \d{2}:\d{2} Uhr<br \/>geändert durch <a href=".+">#{person}<\/a>$/
        )
      end
    end

    context "with deleted current user" do
      let(:user) { Fabricate(:person) }

      before do
        PaperTrail.request.whodunnit = user.id.to_s
        update
        user.destroy!
      end

      it do
        is_expected.to match(
          /^\w+, \d+\. [\w|ä]+ \d{4}, \d{2}:\d{2} Uhr<br \/>geändert durch inzwischen gelöschte Person #{user.id}$/
        )
      end
    end
  end

  def update
    person.update!(town: "Bern", zip_code: "3007")
  end
end
