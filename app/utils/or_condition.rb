# Builder for SQL OR conditions
class OrCondition
    
  def initialize
    @condition = [""]
  end
  
  def or(clause, *args)
    @condition.first << " OR " if present?
    @condition.first << "(#{clause})"
    @condition.push(*args)
  end
  
  def to_a
    @condition
  end
  
  def blank?
    @condition.first.blank?
  end
  
end