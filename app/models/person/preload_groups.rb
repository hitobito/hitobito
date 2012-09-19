module Person::PreloadGroups
  
  GROUP_SELECT_ATTRS = %w(id name type parent_id lft rgt).collect {|a| "groups.#{a}"}
  
  def self.extended(base)
    base.do_preload_groups
  end
  
  def self.for(records)
    records = Array(records)
    
    # preload roles
    ActiveRecord::Associations::Preloader.new(
      records, 
      :roles).run
      
    # preload roles -> group
    ActiveRecord::Associations::Preloader.new(
      records.collect { |record| record.roles }.flatten, 
      :group, 
      :select => GROUP_SELECT_ATTRS).run
      
    # preload groups
    ActiveRecord::Associations::Preloader.new(
      records, 
      :groups, 
      :select => GROUP_SELECT_ATTRS).run
      
    # TODO probably preload group ancestors
    
    records
  end
  
  def do_preload_groups
    @do_preload_groups = true
  end
  
  private
  
  def exec_queries
    records = super
    
    Person::PreloadGroups.for(records) if @do_preload_groups
    
    records
  end
end