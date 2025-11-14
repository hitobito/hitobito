require "spec_helper"

describe "people management", :js do
  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }
  let(:current_user) { people(:root) }
  let(:heading) { "Kinder / Verwalter*innen" }
  let(:top_group) { groups(:top_group) }
  let(:person) { top_leader }
  let(:people_managers_enabled?) { false }
  let(:people_managers_self_service_managed_creation_enabled?) { false }

  def within_turbo_frame
    sign_in(current_user)
    visit group_person_path(group_id: person.primary_group_id, id: person)
    within("turbo-frame#people_managers") do
      yield
    end
  end

  def click_dropdown(text)
    click_link "Erstellen"
    click_link text
  end

  def find_person(name, retries = 0)
    fill_in "Person suchen...", with: name
    find('ul[role="listbox"] li[role="option"]', text: name).click
  rescue Capybara::ElementNotFound => e
    if (retries += 1) <= 3
      puts "#{e.class}, retrying in #{retries} second(s)..."
      sleep(retries)
      retry
    else
      raise
    end
  end

  before do
    allow(FeatureGate).to receive(:enabled?).and_call_original
    allow(FeatureGate).to receive(:enabled?).with("people.people_managers").and_return(people_managers_enabled?)
    allow(FeatureGate).to receive(:enabled?).with("people.people_managers.self_service_managed_creation")
      .and_return(people_managers_self_service_managed_creation_enabled?)
  end

  it "does not show managers since feature is disabled by default" do
    sign_in(current_user)

    visit group_person_path(group_id: person.primary_group_id, id: person)

    expect(page).to have_no_selector("turbo-frame#people_managers")
  end

  context "when feature is enabled" do
    let(:people_managers_enabled?) { true }

    it "can assign and remove manager" do
      within_turbo_frame do
        expect(page).to have_css("h2", text: heading)
        click_dropdown("Verwalter*in zuweisen")
        find_person "Bottom Member"
        click_on "Speichern"
        expect(page).to have_css("h2", text: "Verwalter*innen")
        expect(page).to have_link "Bottom Member"
        expect(page).to have_link "Verwalter*in zuweisen"
        accept_alert("wirklich löschen") do
          click_link "Löschen"
        end
        expect(page).to have_css("h2", text: heading)
        expect(page).not_to have_link "Bottom Member"
      end
    end

    it "can assign and remove managed" do
      within_turbo_frame do
        expect(page).to have_css("h2", text: heading)
        click_dropdown("Kind zuweisen")
        find_person "Bottom Member"
        click_on "Speichern"
        expect(page).to have_css("h2", text: "Kinder")
        expect(page).to have_link "Bottom Member"
        expect(page).to have_link "Kind zuweisen"
        accept_alert("wirklich löschen") do
          click_link "Löschen"
        end
        expect(page).to have_css("h2", text: heading)
        expect(page).not_to have_link "Bottom Member"
      end
    end

    it "shows managed already manager validation error in form" do
      within_turbo_frame do
        bottom_member.people_manageds.create!(managed: current_user)
        click_dropdown("Kind zuweisen")
        find_person "Bottom Member"
        click_on "Speichern"
        expect(page).to have_css(".alert-danger",
          text: "Bottom Member kann nicht sowohl Verwalter*innen als auch Kinder haben.")
      end
    end

    it "shows manager validation errors in form" do
      within_turbo_frame do
        person.people_managers.create!(manager: bottom_member)
        click_dropdown("Verwalter*in zuweisen")
        find_person "Bottom Member"
        click_on "Speichern"
        expect(page).to have_css(".alert-danger", text: "Verwalter*in ist bereits gesetzt.")
      end
    end

    it "shows managed validation errors in form" do
      within_turbo_frame do
        person.people_manageds.create!(managed: bottom_member)
        click_dropdown("Kind zuweisen")
        find_person "Bottom Member"
        click_on "Speichern"
        expect(page).to have_css(".alert-danger", text: "Verwalter*in ist bereits gesetzt.")
      end
    end

    context "without write permission on other persons" do
      let(:person) { current_user }
      let(:current_user) { Fabricate(Group::TopGroup::LocalSecretary.sti_name, group: top_group).person }
      let(:people_managers_self_service_managed_creation_enabled?) { true }

      it "can create and remove managed when feature toggle is enabled" do
        within_turbo_frame do
          expect(page).to have_css("h2", text: heading)
          click_link("Kind erfassen")
          fill_in "Vorname", with: "test"
          fill_in "Nachname", with: "test"
          click_on "Speichern"
          expect(page).to have_css("h2", text: "Kinder")
          expect(page).to have_link "Kind erfassen"
          expect(page).to have_link "test test"
          accept_alert("wirklich löschen") do
            click_link "Löschen"
          end
          expect(page).to have_css("h2", text: heading)
          expect(page).not_to have_link "test test"
        end
      end
    end
  end
end
