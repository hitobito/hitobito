# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class People::PassesController < ApplicationController
  before_action :group, :person, :authorize_action
  before_action :pass, only: [:show, :google_wallet]

  # GET /groups/:group_id/people/:person_id/passes
  def index
    @passes = person.passes
      .includes(:pass_definition, :pass_installations)
  end

  # GET /groups/:group_id/people/:person_id/passes/:id(.pdf|.pkpass)
  def show
    respond_to do |format|
      format.html { render :show }
      format.pdf { render_pdf }
      format.pkpass { render_apple_wallet }
    end
  end

  # GET /groups/:group_id/people/:person_id/passes/:id/google_wallet
  def google_wallet
    redirect_to_google_wallet
  end

  private

  def redirect_to_google_wallet
    pass_installation = find_or_create_pass_installation(:google)
    service = Wallets::GoogleWallet::PassService.new(pass_installation)
    redirect_to service.save_url, allow_other_host: true
  rescue => e
    Rails.logger.error("Google Wallet save failed: #{e.message}")
    redirect_back fallback_location: group_person_path(group, person),
      alert: I18n.t("wallets.google.save_failed")
  end

  def render_apple_wallet
    pass_installation = find_or_create_pass_installation(:apple)
    service = Wallets::AppleWallet::PassService.new(pass, pass_installation: pass_installation)
    send_data service.generate_pass,
      type: Mime[:pkpass],
      disposition: "attachment",
      filename: apple_wallet_filename
  rescue => e
    Rails.logger.error("Apple Wallet generation failed: #{e.message}")
    redirect_back fallback_location: group_person_path(group, person),
      alert: I18n.t("wallets.apple.generation_failed")
  end

  def apple_wallet_filename
    "#{pass_definition.name.parameterize}-#{person.full_name.parameterize}.pkpass"
  end

  def render_pdf
    template = pass_definition.template
    pdf = template.pdf_class.new(pass)
    send_data pdf.render, type: :pdf, disposition: "inline", filename: pdf.filename
  end

  def find_or_create_pass_installation(wallet_type)
    pass_installation = pass.pass_installations.find_or_create_by!(wallet_type: wallet_type) do |pi|
      pi.locale = person.language
    end
    Wallets::PassSynchronizer.new(pass_installation).compute_validity!
    pass_installation
  end

  def pass
    @pass ||= person.passes.find_by!(pass_definition: pass_definition)
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

  def authorize_action
    authorize!(:show, @pass || Pass.new(person: person))
  end
end
