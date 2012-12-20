module NormalizedLabels
  extend ActiveSupport::Concern
  
  included do
    before_save :normalize_label
  end
  
  private
  
  # If a case-insensitive same label already exists, use this one
  def normalize_label
    return if label.blank?
    
    fresh = self.class.available_labels.none? do |l|
      equal = l.casecmp(label) == 0
      self.label = l if equal
      equal
    end
    self.class.sweep_available_labels if fresh
  end
  
  module ClassMethods
    def available_labels
      @available_labels ||= load_available_labels
    end
    
    def sweep_available_labels
      @available_labels = nil
    end
    
    private
    
    def load_available_labels
      order(:label).uniq.pluck(:label).compact
    end
  end
  
  
end