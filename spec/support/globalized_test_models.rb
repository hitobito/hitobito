module GlobalizedTestModels
  class Post < ActiveRecord::Base
    include Globalized

    def self.translated_attribute_names
      %i[title body]
    end

    def self.reflect_on_all_associations
      [StubbedReflection.new]
    end
  end

  class Comment < ActiveRecord::Base
    include Globalized

    def self.translated_attribute_names
      %i[title content]
    end
  end

  class StubbedReflection
    def name
      :comment
    end

    def klass
      Comment
    end
  end

  class ValidatorsTestModel < ActiveRecord::Base
    include Globalized

    def self.translated_attribute_names = [:attr]

    validates :attr, uniqueness: true, presence: true, length: {maximum: 28}
  end
end
