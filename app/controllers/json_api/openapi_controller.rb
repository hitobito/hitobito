# frozen_string_literal: true

class JsonApi::OpenapiController < JsonApi::SchemaController
  include ActionController::MimeResponds

  def show
    respond_to do |format|
      format.json { render json: generate_openapi_spec(:json) }
      format.yaml do
        yaml = generate_openapi_spec(:yaml)
        render plain: yaml, content_type: "text/yaml"
      end
    end
  end

  private

  def generate_openapi_spec(format)
    generator = Graphiti::OpenApi::Generator.new(
      schema: generate_schema,
      jsonapi: Rails.root.join('config', 'jsonapi.json')
    )
    generator.to_openapi(format: format)
  end

end
