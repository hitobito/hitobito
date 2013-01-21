module AddressHelper

  def print_country?(country)
    !['', *Settings.address.ignored_countries].include?(country.to_s.strip.downcase)
  end

end
