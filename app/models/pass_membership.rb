#  Copyright (c) 2025, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PassMembership < ActiveRecord::Base
  belongs_to :person
  belongs_to :pass_definition
  has_many :pass_installations, class_name: "Wallets::PassInstallation", dependent: :destroy

  enum :state, {eligible: 0, ended: 1, revoked: 2}

  validates :person_id, uniqueness: {scope: :pass_definition_id}
end
