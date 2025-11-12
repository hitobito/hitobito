#  Copyright (c) 2012-2025, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"
describe "layouts/_environment_header.html.haml" do
  let(:dom) { Capybara::Node::Simple.new(render) }

  after do
    ENV["HITOBITO_STAGE"] = nil
  end

  it "should show environment when HITOBITO_STAGE env var not set" do
    ENV["HITOBITO_STAGE"] = nil
    expect(dom).to have_content("Umgebung: TEST")
    expect(dom).to have_css(".environment-header")
  end

  it "should show environment when HITOBITO_STAGE env var is set" do
    ENV["HITOBITO_STAGE"] = "some environment"
    expect(dom).to have_css(".environment-header")
    expect(dom).to have_content("Umgebung: SOME ENVIRONMENT")
  end

  it "should not show environment when HITOBITO_STAGE env var is production" do
    ENV["HITOBITO_STAGE"] = "production"
    expect(dom).not_to have_css(".environment-header")
    expect(dom).not_to have_content("Umgebung")
  end
end
