module Person::PreloadGroups
  
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
      :select => Group::MINIMAL_SELECT).run
      
    # preload groups
    ActiveRecord::Associations::Preloader.new(
      records, 
      :groups, 
      :select => Group::MINIMAL_SELECT).run
      
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