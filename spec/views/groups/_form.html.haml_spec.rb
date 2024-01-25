# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'
describe 'groups/_form.html.haml' do
  let(:group) { groups(:top_layer).decorate }
  let(:stubs) { {  model_class: Group, path_args: group,
                   entry: group,
                    } }
  let(:dom) { Capybara::Node::Simple.new(@rendered)  }

  before do
    allow(view).to receive_messages(stubs)
    allow(controller).to receive_messages(current_user: people(:top_leader))
  end

  it 'does render contactable and extension partials' do
    partials = ['_error_messages', '_fields', 'contactable/_fields',
                '_form_tabs', '_general_fields', '_self_registration_fields',
                'contactable/_phone_number_fields', '_phone_number_fields',
                'contactable/_social_account_fields', '_social_account_fields',
                'groups/_form', '_form']

    expect(view).to receive(:render_extensions).with(:form_tabs)
    expect(view).to receive(:render_extensions).with(:address_fields, anything)
    expect(view).to receive(:render_extensions).with(:additional_fields, anything)
    expect(view).to receive(:render_extensions).with(:fields, anything)
    expect(view).to receive(:render_extensions).with(:general_fields, anything)
    expect(view).to receive(:render_extensions).with(:self_registration_fields, anything)
    expect(view).to receive(:render_extensions).with(:mailing_lists_letter_fields, anything)
    render partial: 'groups/form'
    partials.each do |partial|
      expect(view).to render_template(partial: partial)
    end
  end

  it 'disables name and short_name fields' do
    @rendered = render partial: 'groups/form'

    expect(dom).to have_field('Name', disabled: false)
    expect(dom).to have_field('Kurzname', disabled: false)
  end

  context 'static_name group' do
    before { allow(group).to receive(:static_name).and_return(true) }

    it 'disables name and short_name fields' do
      @rendered = render partial: 'groups/form'

      expect(dom).to have_field('Name', disabled: true)
      expect(dom).to have_field('Kurzname', disabled: true)
    end
  end
end
