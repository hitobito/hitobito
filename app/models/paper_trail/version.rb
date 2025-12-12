# frozen_string_literal: true

#  Copyright (c) 2014, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
module PaperTrail
  class Version < ActiveRecord::Base
    include PaperTrail::VersionConcern

    scope :changed, -> { where.not(object_changes: nil) }
    belongs_to :main, polymorphic: true

    # Scoped association for joining roles
    belongs_to :role, -> do
      Role.with_inactive { where("#{PaperTrail::Version.table_name}": {item_type: Role.sti_name}) }
    end, foreign_key: "item_id"

    def perpetrator
      return unless whodunnit.present? && whodunnit_type.present?

      whodunnit_type.safe_constantize&.find_by(id: whodunnit.to_i)
    end
  end
end
