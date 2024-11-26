#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# encoding:  utf-8

require "spec_helper"

describe CustomContentsController, type: :controller do
  class << self
    def it_should_redirect_to_show
      it { is_expected.to redirect_to custom_contents_path(returning: true) }
    end
  end

  let(:test_entry) { custom_contents(:login) }
  let(:test_entry_attrs) { {subject: "New Login", body: "Hej {user}, go here to login: {login-url}"} }

  before { sign_in(people(:top_leader)) }

  include_examples "crud controller", skip: [%w[show], %w[new], %w[create], %w[destroy], %w[index html sort descending]]

  # must be after include_examples
  let(:sort_column) { "label" } # rubocop:disable RSpec/LetBeforeExamples

  describe_action :get, :index do
    context ".html", format: :html do
      it "should contain all entries" do
        expect(entries.size).to eq(CustomContent.count)
      end

      it "should contain all entries in french", perform_request: false do
        I18n.locale = :fr
        perform_request
        expect(entries.size).to eq(CustomContent.count)
      end
    end
  end
end
