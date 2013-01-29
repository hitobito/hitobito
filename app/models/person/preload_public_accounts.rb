module Person::PreloadPublicAccounts

  def self.extended(base)
    base.do_preload_public_accounts
  end
  
  def self.for(records)
    records = Array(records)
    
    # preload accounts
    ActiveRecord::Associations::Preloader.new(
      records,
      :phone_numbers, 
      :conditions => {:public => true}).run
      
    records
  end
  
  def do_preload_public_accounts
    @do_preload_public_accounts = true
  end
  
  private
  
  def exec_queries
    records = super
    
    Person::PreloadPublicAccounts.for(records) if @do_preload_public_accounts
    
    records
  end
end