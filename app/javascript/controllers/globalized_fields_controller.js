//  Copyright (c) 2012-2025, Puzzle ITC. This file is part of
//  hitobito and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/hitobito/hitobito.

import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ['toggle', 'globalizedField', 'globalizedFieldsDisplay', 'localeIndicator']
  static values = {
    additionalLanguagesText: String
  }

  connect() {
    this.updateGlobalizedFieldsDisplay();
    this.openIfInvalid();
  }

  updateGlobalizedFieldsDisplay() {
    const filledOutLanguages = this.globalizedFieldTargets.map(globalizedField => {
      if(globalizedField.value) {
        const id_components = globalizedField.id.split('_');
        return id_components[id_components.length - 1].toUpperCase();
      }
    }).filter(v => v)

    if(filledOutLanguages.length > 0) {
      this.globalizedFieldsDisplayTarget.textContent = `${this.additionalLanguagesTextValue}: ${filledOutLanguages.join(', ')}`;
    } else {
      this.globalizedFieldsDisplayTarget.textContent = '';
    }
  }

  toggleFields() {
    this.toggleTarget.classList.toggle('hidden');
  }

  openIfInvalid() {
    const hasInvalidInput = this.globalizedFieldTargets.some(field => field.classList.contains('is-invalid'));
    if(hasInvalidInput) {
      this.toggleFields();
    }
  }
}
