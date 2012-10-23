module RequestHelpers 
  extend ActiveSupport::Concern


  def included
    Bundler.require(:assets)
  end

  def set_basic_auth(name, password)
    if page.driver.respond_to?(:basic_auth)
      page.driver.basic_auth(name, password)
    elsif page.driver.respond_to?(:basic_authorize)
      page.driver.basic_authorize(name, password)
    elsif page.driver.respond_to?(:browser) && page.driver.browser.respond_to?(:basic_authorize)
      page.driver.browser.basic_authorize(name, password)
    #elsif page.driver.class == Capybara::Poltergeist::Driver
      #page.driver.browser.set_headers 'foo=bar'
    else
      raise "I don't know how to set basic auth!"
    end
  end
end
