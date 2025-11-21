module GlobalizedTestModels
  class Post < ActiveRecord::Base
    include Globalized

    def self.translated_attribute_names
      %i[title body]
    end

    def self.reflect_on_all_associations
      [StubbedReflection.new(:comment, Comment)]
    end
  end

  class Comment < ActiveRecord::Base
    include Globalized

    def self.translated_attribute_names
      %i[title content]
    end

    def self.reflect_on_all_associations
      [StubbedReflection.new(:comment_award, CommentAward)]
    end
  end

  class CommentAward < ActiveRecord::Base
    include Globalized

    def self.translated_attribute_names
      %i[award]
    end
  end

  class StubbedReflection
    def initialize(name, klass)
      @name = name
      @klass = klass
    end

    attr_reader :name

    attr_reader :klass
  end

  class ValidatorsTestModel < ActiveRecord::Base
    include Globalized

    def self.translated_attribute_names = [:attr]

    validates :attr, uniqueness: true, presence: true, length: {maximum: 28}
  end
end
