module CensusEvaluationHelper
  
  EMPTY_COUNT_VALUE = '-'
  
  def census_total_path(group)
    send("census_#{group.klass.model_name.element}_total_group_path", group)
  end
  
  def census_detail_path(group)
    send("census_#{group.klass.model_name.element}_detail_group_path", group)
  end
  
  def count_field(group, field)
    if count = @counts[group.id]
      count_value(count.send(field))
    else
      EMPTY_COUNT_VALUE
    end
  end
  
  def count_value(value)
    value || EMPTY_COUNT_VALUE
  end
end