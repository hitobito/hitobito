module Import
  class AccountFields < SimpleDelegator
    attr_reader :prefix, :human

    def initialize(model)
      @prefix = model.model_name.underscore
      @human = model.model_name.human

      super(map_prefined_fields.with_indifferent_access)
    end

    def fields
      map {|key, value|  { key: key, value: value }  } 
    end

    def key_for(label)
      "#{prefix}_#{label}".downcase
    end

    private
    def map_prefined_fields
      predefined_labels.each_with_object({}) do |label, hash| 
        hash[key_for(label).downcase] = "#{human} #{label}" 
      end
    end

    def predefined_labels
      Settings.send(prefix).predefined_labels
    end
  end
end
