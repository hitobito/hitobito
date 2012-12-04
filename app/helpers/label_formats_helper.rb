module LabelFormatsHelper

  def format_landscape(format)
    format.landscape ? 'Querformat' : 'Hochformat'
  end

end
