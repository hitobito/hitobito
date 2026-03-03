#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class People::PassesController < ApplicationController
  before_action :group, :person

  # GET /groups/:group_id/people/:person_id/passes
  def index
    authorize!(:update, person)
    @pass_memberships = person.pass_memberships
      .includes(:pass_definition, :pass_installations)
  end

  # GET /groups/:group_id/people/:person_id/passes/:id(.pdf|.pkpass)
  def show
    authorize!(:update, person)
    @pass = Pass.new(person: person, definition: pass_definition)

    respond_to do |format|
      format.html { render :show }
      format.pdf { render_pdf }
      format.pkpass { render_apple_wallet }
    end
  end

  # GET /groups/:group_id/people/:person_id/passes/:id/google_wallet
  def google_wallet
    authorize!(:update, person)
    @pass = Pass.new(person: person, definition: pass_definition)

    redirect_to_google_wallet
  end

  private

  def redirect_to_google_wallet
    pass_installation = find_or_create_pass_installation(:google)
    Wallets::PassSynchronizer.new(pass_installation).compute_validity!

    service = Wallets::GoogleWallet::PassService.new(@pass)
    redirect_to service.save_url, allow_other_host: true
  rescue => e
    Rails.logger.error("Google Wallet save failed: #{e.message}")
    redirect_back fallback_location: group_person_path(group, person),
      alert: I18n.t("wallets.google.save_failed")
  end

  def render_apple_wallet
    pass_installation = find_or_create_pass_installation(:apple)
    Wallets::PassSynchronizer.new(pass_installation).compute_validity!

    service = Wallets::AppleWallet::PassService.new(@pass, pass_installation: pass_installation)
    send_data service.generate_pass,
      type: "application/vnd.apple.pkpass",
      disposition: "attachment",
      filename: "pass-#{person.id}-#{pass_definition.id}.pkpass"
  rescue => e
    Rails.logger.error("Apple Wallet generation failed: #{e.message}")
    redirect_back fallback_location: group_person_path(group, person),
      alert: I18n.t("wallets.apple.generation_failed")
  end

  def render_pdf
    template = pass_definition.template
    pdf = template.pdf_class.constantize.new(person, pass_definition)
    I18n.with_locale(person.language) do
      send_data pdf.render, type: :pdf, disposition: "inline", filename: pdf.filename
    end
  end

  def find_or_create_pass_installation(wallet_type)
    pass_membership = person.pass_memberships.find_or_create_by!(
      pass_definition: pass_definition
    ) do |pm|
      # Edge Case: PassMembershipPopulateJob hat noch nicht gelaufen,
      # aber Person klickt bereits auf "Add to Wallet".
      # Gültigkeitsdaten aus Pass PORO berechnen.
      pm.state = @pass.eligible? ? :eligible : :ended
      pm.valid_from = @pass.valid_from
      pm.valid_until = @pass.valid_until
    end
    pass_membership.pass_installations.find_or_create_by!(wallet_type: wallet_type) do |pi|
      pi.wallet_identifier = SecureRandom.uuid
    end
  end

  def person
    @person ||= Person.find(params[:person_id])
  end

  def pass_definition
    @pass_definition ||= PassDefinition.find(params[:id])
  end

  def group
    @group ||= Group.find(params[:group_id])
  end
end
