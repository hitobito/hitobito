# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe TableDisplays::People::LoginStatusColumn, type: :helper do
  include UtilityHelper
  include FormatHelper

  let(:person) { people(:bottom_member).decorate }
  let(:ability) { Ability.new(person) }
  let(:table) { StandardTableBuilder.new([person], self) }

  before do
    allow(person).to receive(:login_status_icon).and_return("login_status_icon")
  end

  it_behaves_like "table display", {
    column: :login_status,
    header: "Login",
    value: "login_status_icon",
    permission: :show
  }
end
