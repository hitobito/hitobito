class ApplicationDecorator < Draper::Base
  delegate :to_s, to: :model
  delegate :can?, :content_tag, :safe_join, :current_user, to: :h

  ## custom access to model class
  # model_class from draper does not play well with STI
  def klass
    model.class
  end
  
  def used_attributes(*attributes)
    attributes.select { |name| model.class.attr_used?(name) }.map(&:to_s)
  end

  def used?(attribute)
    used_attributes(attribute).each { |a| yield }
  end

  def updated_info
    html = ""
    html << l(updated_at, format: :date_time)
    html << " "
    html << h.link_to(updater.to_s, h.person_path(id: updater.id)) if updater.present?
    html.html_safe
  end

  def created_info
    html = ""
    html << l(created_at, format: :date_time)
    html << " "
    html << h.link_to(creator.to_s, h.person_path(id: creator.id)) if creator.present?
    html.html_safe
  end

end
