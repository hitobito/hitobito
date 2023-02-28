# frozen_string_literal: true

#  Copyright (c) 2014, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: versions
#
#  id             :integer          not null, primary key
#  event          :string(255)      not null
#  item_type      :string(255)      not null
#  main_type      :string(255)
#  object         :text(16777215)
#  object_changes :text(16777215)
#  whodunnit      :string(255)
#  created_at     :datetime
#  item_id        :integer          not null
#  main_id        :integer
#
# Indexes
#
#  index_versions_on_item_type_and_item_id  (item_type,item_id)
#  index_versions_on_main_id_and_main_type  (main_id,main_type)
#

module PaperTrail
  class Version < ActiveRecord::Base

    include PaperTrail::VersionConcern

    belongs_to :main, polymorphic: true

    # Scoped association for joining roles
    belongs_to :role, -> do
      Role.with_deleted { where("#{PaperTrail::Version.table_name}": { item_type: Role.sti_name }) }
    end, foreign_key: 'item_id'

    def perpetrator
      return unless whodunnit.present? && whodunnit_type.present?

      whodunnit_type.safe_constantize&.find_by(id: whodunnit.to_i)
    end
  end
end
