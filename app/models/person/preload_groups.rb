module Person::PreloadGroups
  
  GROUP_SELECT_ATTRS = %w(id name type).collect {|a| "groups.#{a}"}
  
  def self.extended(base)
    base.do_preload_groups
  end
  
  def do_preload_groups
    @do_preload_groups = true
  end
  
  private
  
  def exec_queries
    records = super
    
    if @do_preload_groups
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
    end
    
    records
  end
end