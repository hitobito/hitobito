# frozen_string_literal: true
#
#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

# Concern for pseudo-models which can be used in CRUD controllers but are not
# persisted to the database, but rather delegate saving to effective models.
module TransientModel
  extend ActiveSupport::Concern

  include ActiveModel::Model
  include ActiveModel::Validations
  extend ActiveModel::Naming

  def self.base_class
    self.class
  end

  def new_record?
    true
  end
end
