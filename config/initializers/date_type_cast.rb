class ActiveRecord::ConnectionAdapters::Column
  
  class << self
    
    def date_string_to_long_year(string)
      return string unless string.is_a?(String)
      return nil if string.empty?
      
      if string.strip =~ /\A(\d+)\.(\d+)\.(\d{2})\z/
        long_year = 1900 + $3.to_i
        long_year += 100 if long_year < 1940
        string = "#{$1}.#{$2}.#{long_year}"
      end
      
      string
    end
    
    protected
     
    def fallback_string_to_date_with_long_year(string)
      fallback_string_to_date_without_long_year(date_string_to_long_year(string))
    end
    
    alias_method_chain :fallback_string_to_date, :long_year
    
  end
end