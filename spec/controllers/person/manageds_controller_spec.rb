# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"
require_relative "people_managers_shared_examples"

describe Person::ManagedsController do
  it_behaves_like "people_managers#create"
  it_behaves_like "people_managers#destroy"
end
