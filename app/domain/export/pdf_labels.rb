module Export
  class PdfLabels
    FONT_NAME = 'Helvetica'
    
    attr_reader :format
    
    def initialize(format)
      @format = format
    end
    
    def generate(contactables)
      pdf = Prawn::Document.new(page_size: format.page_size, 
                                page_layout: format.page_layout, 
                                margin: 0.mm) 
      pdf.font FONT_NAME, size: format.font_size
      
      contactables.each_with_index do |contactable, i|
        # currently, no bounding box to make overflows visible.
        # this is desired by the customer..
        #pdf.bounding_box(position(pdf, i), width: format.width.mm, height: format.height.mm) do
          #pdf.stroke_bounds
          pos = position(pdf, i)
          
          pdf.text_box(address(contactable), at: [pos.first + format.padding_left.mm, 
                                                  pos.last - format.padding_top.mm])
        #end
      end
      
      pdf.render
    end
    
    private

    def address(contactable)
      address = ""
      if contactable.respond_to?(:company) && contactable.company? && contactable.company_name?
        address << contactable.company_name << "\n"
      end
      address << contactable.full_name << "\n"
      address << contactable.address.to_s
      address << "\n" unless contactable.address =~ /\n\s*$/
      address << contactable.zip_code.to_s << " " << contactable.town.to_s << "\n"
      unless ['', 'ch', 'schweiz'].include?(contactable.country.to_s.strip.downcase)
        address << contactable.country
      end
      address
    end
      
    def position(pdf, i)
      page_index = i % (format.count_horizontal * format.count_vertical)
      if page_index == 0 && i > 0
        pdf.start_new_page
      end
      
      x = page_index % format.count_horizontal
      y = page_index / format.count_horizontal
      
      [x * format.width.mm, pdf.margin_box.height - (y * format.height.mm)]
    end
  
  end
end