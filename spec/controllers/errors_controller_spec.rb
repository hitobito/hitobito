# frozen_string_literal: true

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe ErrorsController do

  render_views

  %w(404 500 503).each do |code|
    it "renders #{code} with correct view and status code" do
      get :"show#{code}"
      expect(response).to render_template(code)
      expect(response.status).to eq code.to_i
    end
  end

  describe 'Content-Type' do
    %w(html json).each do |format|
      it "renders #{format} for #{format} format" do
        get :show404, format: format.to_sym
        expect(response).to render_template('404')
        expect(response.status).to eq 404
        expect(response.content_type).to match(Regexp.new(format))
      end
    end

    %w(png jpeg).each do |format|
      it "renders html for #{format}" do
        get :show404, format: format.to_sym
        expect(response).to render_template('404')
        expect(response.status).to eq 404
        expect(response.content_type).to match(/html/)
      end
    end
  end
end
