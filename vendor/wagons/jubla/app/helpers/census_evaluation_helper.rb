module CensusEvaluationHelper
  
  EMPTY_COUNT_VALUE = '-'
  
  def census_evaluation_path(group, options = {})
    send("census_#{group.klass.model_name.element}_group_path", group, options)
  end
  
  
  def count_field(group, field)
    if count = @group_counts[group.id]
      count_value(count.send(field))
    else
      EMPTY_COUNT_VALUE
    end
  end
  
  def count_value(value)
    value.to_i > 0 ? value : EMPTY_COUNT_VALUE
  end
  
end