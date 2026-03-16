#  Copyright (c) 2026 Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe PaperTrail::VersionAuthorPresenter, :draper_with_helpers, versioning: true do
  let(:person) { people(:top_leader) }
  let(:version) { PaperTrail::Version.where(main_id: person.id).order(:created_at, :id).last }
  let(:view_context) { ActionController::Base.new.view_context }
  let(:presenter) { PaperTrail::VersionAuthorPresenter.new(version, view_context) }

  before do
    PaperTrail.request.whodunnit = nil
    view_context.extend(Rails.application.routes.url_helpers)
    allow(view_context).to receive(:url_options).and_return({
      host: "localhost",
      locale: I18n.locale
    })
  end

  subject { presenter.render }

  context "without current user" do
    before { update }

    it { is_expected.to be_nil }
  end

  context "with current user" do
    before do
      PaperTrail.request.whodunnit = person.id.to_s
      update
    end

    context "and permission to link" do
      it do
        expect(presenter.h).to receive(:can?).with(:show, person).and_return(true)
        is_expected.to match(/^<a href=".+">#{person}<\/a>$/)
      end
    end

    context "and no permission to link" do
      it do
        expect(presenter.h).to receive(:can?).with(:show, person).and_return(false)
        is_expected.to eq(person.to_s)
      end
    end
  end

  context "with service token" do
    let(:service_token) { service_tokens(:permitted_top_layer_token) }

    before do
      PaperTrail.request.whodunnit = service_token.id.to_s
      PaperTrail.request.controller_info = {whodunnit_type: ServiceToken.sti_name}
      update
    end

    context "and permission to link" do
      it do
        expect(presenter.h).to receive(:can?).with(:show, service_token).and_return(true)
        is_expected.to match(/^<a href=".+">API-Key: Permitted<\/a>$/)
      end
    end

    context "and no permission to link" do
      it do
        expect(presenter.h).to receive(:can?).with(:show, service_token).and_return(false)
        is_expected.to eq("API-Key: Permitted")
      end
    end
  end

  def update
    person.update!(town: "Bern", zip_code: "3007")
  end
end
