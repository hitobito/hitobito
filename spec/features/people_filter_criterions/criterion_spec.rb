require "spec_helper"

describe "Filter Criterion", js: true do
  let(:person) { people(:root) }
  let(:group) { groups(:top_layer) }

  before do
    sign_in(person)
    visit new_group_people_filter_path(group)
  end

  it "adds role partial" do
    select_attribute("role")
    expect(page).to have_selector("h3", text: "Rollen")
    expect(page).to have_no_selector("#dropdown-option-role")
  end

  it "adds qualification partial" do
    select_attribute("qualification")
    expect(page).to have_selector("h3", text: "Qualifikationen")
    expect(page).to have_no_selector("#dropdown-option-qualification")
  end

  it "removes partial" do
    select_attribute("attributes")

    expect(page).to have_selector("h3", text: "Felder")

    find(".fa-times").click
    expect(page).to have_no_selector("h3", text: "Felder")
    expect(page).to have_selector("#dropdown-option-attributes", visible: false)
  end

  it "hides filter advice and dropdown when all criteria selected" do
    expect(page).to have_selector("#filter-advice")
    expect(page).to have_selector(".dropdown-toggle")

    select_attribute("role")
    select_attribute("tag")
    select_attribute("attributes")
    select_attribute("qualification")

    expect(page).to have_css("#filter-advice.d-none", visible: false)
    expect(page).to have_no_selector(".dropdown-toggle")
  end

  def select_attribute(attr)
    all(".dropdown-toggle")[0].click
    find("#dropdown-option-#{attr}").click
    sleep(0.3)
  end
end
