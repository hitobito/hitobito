# encoding: utf-8

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module TypeId
  extend ActiveSupport::Concern

  included do
    class_attribute :id, instance_reader: false, instance_writer: false
  end

  module ClassMethods
    @@types_by_id = {}

    def inherited(subclass)
      super
      next_id = @@types_by_id.present? ? @@types_by_id.keys.max + 1 : 1
      subclass.id = next_id
      @@types_by_id[next_id] = subclass
    end

    def type_by_id(id)
      @@types_by_id[id]
    end

    def types_by_ids(ids)
      ids.collect { |id| type_by_id(id) }.compact
    end

    def types_by_id
      @@types_by_id.dup
    end
  end

end
