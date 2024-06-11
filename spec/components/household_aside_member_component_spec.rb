# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe HouseholdAsideMemberComponent, type: :component do
  let(:person) { people(:bottom_member) }
  let(:leader) { people(:top_leader) }
  subject(:component) { described_class.new(person: person) }

  before do
    leader.update(household_key: 1, birthday: 38.years.ago)
    person.update(household_key: 1)
  end

  it 'renders a person in the household with link' do
    allow(component).to receive(:link_person?).and_return(true)
    rendered_component = render_inline(component).to_html.squish
    expect(
      rendered_component
    ).to include(
      '<a data-turbo-frame="_top" href="/people/572407901">Top Leader</a></strong>'
    )

    expect(
      rendered_component
    ).to have_text 'Top Leader'
  end

  it 'renders a person in the household without link' do
    allow(component).to receive(:link_person?).and_return(false)
    rendered_component = render_inline(component).to_html.squish

    expect(
      rendered_component
    ).to include(
      '<strong>Top Leader</strong>'
    )

    expect(rendered_component).to have_text('Top Leader')
  end
end
