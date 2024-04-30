// Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
// hitobito_sac_cas and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito
//
// This has been extracted from app/javascript/javascripts/modules/remote_autocomplete.js
// and wrapped as a stimulus controller to cater for 422 responses not triggering load events
// see https://github.com/hitobito/hitobito/issues/2565


import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    window.App.setupRemoteAutocomplete();
  }
}
