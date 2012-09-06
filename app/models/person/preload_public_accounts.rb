module Person::PreloadPublicAccounts

  def self.extended(base)
    base.do_preload_public_accounts
  end
  
  def do_preload_public_accounts
    @do_preload_public_accounts = true
  end
  
  private
  
  def exec_queries
    records = super
    
    if @do_preload_public_accounts
      # preload roles
      ActiveRecord::Associations::Preloader.new(
        records, 
        [:phone_numbers, :social_accounts], 
        :conditions => {:public => true}).run
    end
    
    records
  end
end