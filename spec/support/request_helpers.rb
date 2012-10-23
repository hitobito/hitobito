module RequestHelpers 

  def sign_in(email, password)
    visit person_session_path
    fill_in 'Email', with: email
    fill_in 'Passwort', with: password
    click_button 'Anmelden'
  end

  # not now
  private
  def set_basic_auth(name, password)
    if page.driver.respond_to?(:basic_auth)
      page.driver.basic_auth(name, password)
    elsif page.driver.respond_to?(:basic_authorize)
      page.driver.basic_authorize(name, password)
    elsif page.driver.respond_to?(:browser) && page.driver.browser.respond_to?(:basic_authorize)
      page.driver.browser.basic_authorize(name, password)
    elsif page.driver.class == Capybara::Poltergeist::Driver
      encoded = Base64.encode64("#{name}:#{password}").strip
      page.driver.headers = { "Authorization" => "Basic #{encoded}" } 
    else
      raise "I don't know how to set basic auth!"
    end
  end

end
