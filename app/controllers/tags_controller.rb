class TagsController < SimpleCrudController
  self.permitted_attrs = [:name]

  private

  def self.model_class
    ActsAsTaggableOn::Tag
  end

  def index_path
    tags_path(returning: true)
  end
end
