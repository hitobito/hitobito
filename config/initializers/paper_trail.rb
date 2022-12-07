PaperTrail::Version.class_eval do
  def perpetrator
    #if whodunnit.present? && whodunnit_type.present?
      #whodunnit_entry = whodunnit_type.constantize.find(whodunnit.to_i) 

      #if whodunnit_entry.is_a?(Oauth::AccessToken)
        #whodunnit_entry.person
      #else
        #whodunnit_entry
      #end
    #end
    if whodunnit.present? && whodunnit_type.present?
      whodunnit_type.constantize.find(whodunnit.to_i) 
    end
  end
end
