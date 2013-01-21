module Export
  class PdfLabels
    
    attr_reader :format

    include AddressHelper
    
    def initialize(format)
      @format = format
    end
    
    def generate(contactables)
      pdf = Prawn::Document.new(page_size: format.page_size, 
                                page_layout: format.page_layout, 
                                margin: 0.mm) 
      pdf.font Settings.pdf.labels.font_name, size: format.font_size
      
      contactables.each_with_index do |contactable, i|
        print_address(pdf, address(contactable), position(pdf, i))
      end
      
      pdf.render
    end

    private
    
    def print_address_in_bounding_box(pdf, address, pos)
      pdf.bounding_box(pos, width: format.width.mm, height: format.height.mm) do
        pdf.stroke_bounds
        
        pdf.text_box(address, at: [format.padding_left.mm, 
                                   format.height.mm - format.padding_top.mm])
      end
    end
    
    def print_address(pdf, address, pos)
      pdf.text_box(address, at: [pos.first + format.padding_left.mm, 
                                 pos.last - format.padding_top.mm])
    end

    def address(contactable)
      address = ""
      address << contactable.company_name << "\n" if print_company?(contactable)
      address << contactable.full_name << "\n"
      address << contactable.address.to_s
      address << "\n" unless contactable.address =~ /\n\s*$/
      address << contactable.zip_code.to_s << " " << contactable.town.to_s << "\n"
      address << contactable.country if print_country?(contactable.country)
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
    
    def print_company?(contactable)
      contactable.respond_to?(:company) && contactable.company_name?
    end
  
  end
end
