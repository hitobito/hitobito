#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# encoding:  utf-8

require "spec_helper"

describe LabelFormatsController, type: :controller do
  class << self
    def it_should_redirect_to_show
      it { is_expected.to redirect_to label_formats_path(returning: true) }
    end
  end

  let(:test_entry) { label_formats(:standard) }
  let(:test_entry_attrs) do
    {name: "foo",
     page_size: "A4",
     landscape: true,
     font_size: 12.0,
     width: 99.0,
     height: 99.0,
     count_horizontal: 22,
     count_vertical: 22,
     padding_top: 2.0,
     padding_left: 2.0}
  end

  before { Fabricate(:label_format, person: people(:top_leader)) }

  before { sign_in(people(:top_leader)) }

  include_examples "crud controller", skip: [%w[show]]

  # must be after include_examples
  let(:sort_column) { "name" } # rubocop:disable RSpec/LetBeforeExamples

  describe_action :get, :index do
    context ".html", format: :html do
      it "should contain all entries" do
        expect(entries.size).to eq(LabelFormat.where(person_id: user.id).count)
        expect(assigns(:global_entries).size).to eq(LabelFormat.global.count)
      end

      it "should contain all entries in french", perform_request: false do
        I18n.locale = :fr
        perform_request
        expect(entries.size).to eq(LabelFormat.where(person_id: user.id).count)
        expect(assigns(:global_entries).size).to eq(LabelFormat.global.count)
      end
    end
  end

  describe_action :get, :index do
    context ".html", format: :html do
      it "should mark nav link as active" do
        expect(response.body).to have_selector(".nav-left-list li.is-active", text: "Etikettenformate")
      end
    end
  end
end
