module QualificationsHelper
  
  def format_qualification_kind_validity(kind)
    "#{f(kind.validity)} Jahre"
  end
end