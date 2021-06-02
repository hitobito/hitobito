# frozen_string_literal: true

module ParamConverters

  private

  def list_param(key, model = nil)
    param = model ? params[model][key] : params[key]
    param.to_s.split(',').map(&:strip)
  end

  def true?(value)
    %w(1 yes true).include?(value.to_s.downcase)
  end

end
