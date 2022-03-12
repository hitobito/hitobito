# encoding: utf-8

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::KindCategoriesController < SimpleCrudController

  self.permitted_attrs = [:label, :order, kinds: []]

  self.sort_mappings = { label: 'event_kind_category_translations.label' }

  before_render_form :load_assocations


  private

  def load_assocations
    @kinds = possible_kinds
  end

  def possible_kinds
    @possible_kinds ||= Event::Kind.without_deleted.list
  end

  class << self
    def model_class
      Event::KindCategory
    end
  end

end
