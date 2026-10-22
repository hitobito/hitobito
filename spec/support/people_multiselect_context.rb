#  Copyright (c) 2025, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Three filtered members, plus bystanders that are not part of the filter. Bulk actions must
# only touch the selected people, which the including group defines via one of the
# selection contexts below.
shared_context "people multiselect" do
  let(:group) { groups(:top_group) }
  let(:user) { people(:top_leader) }
  let(:member_type) { Group::TopGroup::Member }

  let!(:members) do
    Array.new(3) { Fabricate(member_type.name.to_sym, group: group).person }
  end
  let!(:bystanders) do
    Array.new(2) { Fabricate(Group::TopGroup::LocalSecretary.name.to_sym, group: group).person }
  end

  let(:unselected) { (members + bystanders) - selected }
  let(:count) { selected.size }

  let(:filter_params) do
    {range: "group", filters: {role: {role_type_ids: member_type.type_id}}}
  end

  before { sign_in(user) }

  def open_people_list
    visit group_people_path(group, **filter_params)
    select_people
  end

  # the redirect after a bulk action shows the whole group, so make sure every person is on page 1
  def show_unpaginated_people_list
    allow(Kaminari.config).to receive(:default_per_page).and_call_original
  end

  def roles_of(people)
    Role.where(person_id: people.map(&:id))
  end

  def taggings_of(people)
    ActsAsTaggableOn::Tagging.where(taggable_id: people.map(&:id))
  end
end

# Selects two of the filtered members one by one, so their ids are submitted
shared_context "single people selected" do
  let(:selected) { members.first(2) }

  def select_people
    selected.each { |person| find("input[name='ids[]'][value='#{person.id}']").click }
    expect(page).to have_content("#{selected.size} ausgewählt")
  end
end

# Selects all filtered members via "Alle n auswählen", so ids=all and the list filter are submitted
shared_context "all filtered people selected" do
  let(:selected) { members }

  before { allow(Kaminari.config).to receive(:default_per_page).and_return(2) }

  def select_people
    find("#all").click
    expect(page).to have_content("2 ausgewählt")
    expect(page).to have_content("Alle 3 auswählen")
    find("label.extended_all").click
    expect(page).to have_content("3 ausgewählt")
  end
end
