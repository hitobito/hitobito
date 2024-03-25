# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require 'spec_helper'

describe 'subscriber/filter/_show.html.haml' do
  let(:entry) { mailing_lists(:leaders) }

  before do
    allow(view).to receive(:can?).and_return(true)
    assign(:group, entry.group)
    assign(:mailing_list, entry)
  end

  subject { Capybara::Node::Simple.new(render) }

  it 'renders edit link if user can update filter_chain attr' do
    allow(view).to receive(:can?).with(:update, entry, :filter_chain).and_return(true)

    expect(subject).to have_link href: edit_group_mailing_list_filter_path(entry.group, entry)
  end

  it 'does not render edit link if user cannot update filter_chain attr' do
    allow(view).to receive(:can?).with(:update, entry, :filter_chain).and_return(false)

    expect(subject).to have_no_link href: edit_group_mailing_list_filter_path(entry.group, entry)
  end
end
