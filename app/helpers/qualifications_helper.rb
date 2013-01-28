# encoding: UTF-8
module QualificationsHelper
  
  def format_qualification_kind_validity(kind)
    format_unbounded_value(kind.validity) {|d| "#{d} Jahre" }
  end
  
  def format_qualification_finish_at(quali)
    format_unbounded_value(quali.finish_at) {|d| "bis #{d}" }
  end
  
  private
  
  def format_unbounded_value(value)
    if value.present?
      yield f(value)
    else
      "unbeschränkt"
    end
  end
  
end
