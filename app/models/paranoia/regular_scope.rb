module Paranoia
  module RegularScope
    
    # Do not exclude deleted entries in default scope.
    # Benefit: When an association references a deleted entry,
    # this entry is still found and may be displayed.
    # Tradeoff: When choosing an associated entry, the scope 
    # :without_deleted has to specified explicitly.
    def default_scope
      scoped.with_deleted
    end

    def without_deleted
      scoped.where(:deleted_at => nil)
    end
    
  end
end
