#  Copyright (c) 2017, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Dropdown::Event
  class EventsExport < Dropdown::Base
    attr_reader :user, :params

    def initialize(template, params)
      super(template, translate(:button), :download)
      @params = params

      init_items
    end

    private

    def init_items
      tabular_links(:csv)
      tabular_links(:xlsx)
    end

    def tabular_links(format)
      add_item(translate(format), params.merge(format: format))
    end
  end
end
