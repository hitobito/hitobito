# encoding: utf-8
# == Schema Information
#
# Table name: versions
#
#  id             :integer          not null, primary key
#  item_type      :string           not null
#  item_id        :integer          not null
#  event          :string           not null
#  whodunnit      :string
#  object         :text
#  object_changes :text
#  main_type      :string
#  main_id        :integer
#  created_at     :datetime
#


#  Copyright (c) 2014, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module PaperTrail
  class Version < ActiveRecord::Base

    include PaperTrail::VersionConcern

    belongs_to :main, polymorphic: true

  end
end
