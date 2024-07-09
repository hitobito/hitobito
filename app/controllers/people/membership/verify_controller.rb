# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizerischer Kanu-Verband. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class People::Membership::VerifyController < ActionController::Base # rubocop:disable Rails/ApplicationController
  helper_method :person, :root, :member?

  skip_authorization_check

  def show
    return head :not_found unless feature_enabled?

    render layout: false
  end

  private

  def person
    @person ||= fetch_person
  end

  def fetch_person
    token = params[:verify_token]
    return nil if token.blank?

    Person.find_by(membership_verify_token: params[:verify_token])
  end

  def root
    Group.root.decorate
  end

  def member?
    @member ||= People::Membership::Verifier.new(person).member?
  end

  def feature_enabled?
    People::Membership::Verifier.enabled?
  end
end
