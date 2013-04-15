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
    rescue Capybara::Poltergeist::ObsoleteNode => e1
      pending
    rescue Capybara::Poltergeist::TimeoutError => e2
      pending
    end
  end

end
