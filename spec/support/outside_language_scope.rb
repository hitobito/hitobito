module OutsideLanguageScope
  FILTER_PATHS = %w[/api/ /json_api/ /resources/].freeze

  RSpec.configure do |config|
    config.before do |example|
      metadata = example.metadata
      if outside_language_scope?(metadata[:file_path]) || metadata.key?(:outside_language_scope)
        updated_default_url_options = Rails.application.default_url_options.dup
        updated_default_url_options[:locale] = nil
        allow(Rails.application.routes).to receive(:default_url_options).and_return(updated_default_url_options)
      end
    end
  end

  def outside_language_scope?(file_path)
    FILTER_PATHS.any? { |filter_path| file_path.include?(filter_path) }
  end
end
