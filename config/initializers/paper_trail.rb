# encoding: utf-8

#  Copyright (c) 2014, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module PaperTrail
  class Version < ActiveRecord::Base
    schema_validations auto_create: false

    attr_accessible :main_id, :main_type, :main

    belongs_to :main, polymorphic: true
  end
end