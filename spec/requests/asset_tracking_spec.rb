# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "asset tracking", type: :request do
  let(:person) { people(:top_leader) }

  before { sign_in(person) }

  def dom = Capybara::Node::Simple.new(response.body)

  def tracked_values
    response.body.scan(/<(?:link|script)[^>]+data-turbo-track="([^"]*)"/).flatten
  end

  # Turbo compares the tracked elements of the current and the incoming page and
  # forces a full page load when they differ - which is how a tab that has been
  # open across a deploy picks up the new bundles instead of silently keeping the
  # old ones. It only considers elements whose attribute is exactly "reload";
  # anything else, "true" included, is ignored without warning.
  #
  # Outside production the attribute is left off entirely (see
  # LayoutHelper#turbo_track), so that hotwire-livereload can swap the stylesheet
  # instead of being forced into a full reload by the changed digest.
  it "leaves the bundles of the application layout untracked outside production" do
    get group_path(groups(:top_layer))

    expect(dom).to have_css("link[rel=stylesheet]", visible: :all)
    expect(tracked_values).to be_empty
  end
end
