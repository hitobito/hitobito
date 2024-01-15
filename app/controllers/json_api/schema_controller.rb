# frozen_string_literal: true

class JsonApi::SchemaController < ActionController::API

  # All graphiti resources must be loaded to generate the schema
  before_action :require_all_resources

  def show
    render json: generate_schema
  end

  private

  def generate_schema
    Graphiti::Schema.generate
  end

  def require_all_resources
    Dir.glob("#{Rails.root}/app/resources/**/*.rb").each do |f|
      require f
    end
  end

end
