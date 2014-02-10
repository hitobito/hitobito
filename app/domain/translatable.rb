module Translatable

  private

  def translate(key, options={})
    @translation_prefix ||= self.class.to_s.underscore.gsub('_controller', '')
    I18n.t([@translation_prefix,key].join('.'), options)
  end

end
