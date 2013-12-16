module TypeId
  extend ActiveSupport::Concern


  included do
    class_attribute :id
  end

  module ClassMethods
    @@types_by_id = {}

    def inherited(subclass)
      super(subclass)
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