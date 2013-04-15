module RequestHelpers

  def sign_in(user = nil)
    user ||= people(:top_leader)
    visit person_session_path
    fill_in 'E-Mail', with: user.email
    fill_in 'Passwort', with: 'foobar'
    click_button 'Anmelden'
  end

  private

  def obsolete_node_safe
    begin
      yield
    rescue Capybara::TimeoutError,
           Capybara::ElementNotFound,
           Capybara::Poltergeist::ObsoleteNode,
           Capybara::Poltergeist::TimeoutError => e
      pending
    end
  end

end
