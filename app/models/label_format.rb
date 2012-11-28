class LabelFormat < ActiveRecord::Base
  
  attr_accessible :name, :page_size, :landscape, :font_size, :width, :height, 
                  :padding_top, :padding_left, :count_horizontal, :count_vertical
  
 
  validates :page_size, inclusion: Prawn::Document::PageGeometry::SIZES.keys
 
  validates :width, :height, :font_size, :count_horizontal, :count_vertical,
            numericality: {greater_than_or_equal_to: 1, allow_nil: true}
            
  validates :padding_top, :padding_left,
            numericality: {greater_than_or_equal_to: 0, allow_nil: true}
  
  after_save :sweep_cache
  after_destroy :sweep_cache

  def to_s
    "#{name} (#{page_size}, #{dimensions})"
  end
  
  def dimensions
    "#{count_horizontal}x#{count_vertical}"
  end
  
  def page_layout
    landscape ? :landscape : :portrait
  end
  
  private
  
  def sweep_cache
    Rails.cache.delete('label_formats')
  end
end