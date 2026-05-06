# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class Person::PassesController < CrudController
  self.nesting = [Group, Person]

  alias_method :pass, :entry
  delegate :pass_definition, :person, to: :pass
  skip_authorize_resource only: :google_wallet

  def show
    respond_to do |format|
      @pass = entry.decorate # template partials require decorated pass @ivar
      @pass_definition = entry.pass_definition
      format.html
      format.pdf { render_pdf }
      format.pkpass { render_apple_wallet }
    end
  end

  def google_wallet
    authorize!(:show, pass)
    redirect_to_google_wallet
  end

  private

  def list_entries
    super.includes(:pass_definition, :pass_installations, :person)
  end

  def redirect_to_google_wallet
    pass_installation = find_or_create_pass_installation(:google)
    service = Wallets::GoogleWallet::PassService.new(pass_installation)
    redirect_to service.save_url, allow_other_host: true
  rescue => e
    log_and_redirect(:google, e)
  end

  def render_apple_wallet
    pass_installation = find_or_create_pass_installation(:apple)
    service = Wallets::AppleWallet::PassService.new(pass, pass_installation: pass_installation)
    send_data service.generate_pass,
      type: Mime[:pkpass],
      disposition: "attachment",
      filename: "#{pass_definition.name.parameterize}-#{person.full_name.parameterize}.pkpass"
  rescue => e
    log_and_redirect(:apple, e)
  end

  def log_and_redirect(key, e)
    Rails.logger.error("#{key.upcase} Wallet generation failed: #{e.message}")
    redirect_back fallback_location: group_person_path(@group, @person),
      alert: I18n.t("wallets.#{key}.generation_failed")
  end

  def render_pdf
    template = pass_definition.template
    pdf = template.pdf_class.new(pass)
    send_data pdf.render, type: :pdf, disposition: "inline", filename: pdf.filename
  end

  def find_or_create_pass_installation(wallet_type)
    state = Wallets::PassSynchronizer::PASS_INSTALLATION_STATE_MAP.fetch(pass.state.to_sym)
    pass.pass_installations.find_or_create_by(wallet_type: wallet_type) do |pi|
      pi.locale = person.language
      pi.state = state
    end
  end

  def authorize_class
    authorize!(:show, Pass.new(person: person))
  end
end
