
module MountedAttr
  extend ActiveSupport::Concern

  module ClassMethods
    def mounted_attr(attr, type, options = {})
      define_method("#{attr}=") do |value|
        entry = MountedAttribute.find_by(entry_id: self.id,
                                        entry_type: self.class.sti_name,
                                        key: attr)

        if entry.present?
          entry.update!(value: value)
        else
          MountedAttribute.create!(entry_id: self.id,
                                   entry_type: self.class.sti_name,
                                   key: attr,
                                   value: value)
        end
      end

      define_method(attr) do
        MountedAttribute.find_by(entry_id: self.id,
                                 entry_type: self.class.sti_name,
                                 key: attr)&.value
      end
    end
  end

end
