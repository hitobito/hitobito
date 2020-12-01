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
#  item_type      :string(255)      not null
#  item_id        :integer          not null
#  event          :string(255)      not null
#  whodunnit      :string(255)
#  object         :text(65535)
#  object_changes :text(65535)
#  main_type      :string(255)
#  main_id        :integer
#  created_at     :datetime
#

module PaperTrail
  class Version < ActiveRecord::Base

    include PaperTrail::VersionConcern

    belongs_to :main, polymorphic: true

  end
end
