# encoding: UTF-8
module QualificationsHelper
  
  def format_qualification_kind_validity(kind)
    if kind.validity.present?
      "#{f(kind.validity)} Jahre"
    else
      "unbeschränkt"
    end
  end
end
