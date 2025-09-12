//  Copyright (c) 2012-2025, Puzzle ITC. This file is part of
//  hitobito and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/hitobito/hitobito.

import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ['toggle', 'translatedField', 'translatedFieldsDisplay']
  static values = {
    additionalLanguagesText: String
  }

  connect() {
    this.updateTranslatedFields();
    this.openIfInvalid();
  }

  updateTranslatedFields() {
    const translatedLanguages = this.translatedFieldTargets.map(translatedField => {
      if(translatedField.value) {
        const id_components = translatedField.id.split('_');
        return id_components[id_components.length - 1].toUpperCase();
      }
    }).filter(v => v)

    if(translatedLanguages.length > 0) {
      this.translatedFieldsDisplayTarget.textContent = `${this.additionalLanguagesTextValue}: ${translatedLanguages.join(', ')}`;
    } else {
      this.translatedFieldsDisplayTarget.textContent = '';
    }
  }

  toggleFields() {
    this.toggleTarget.classList.toggle('hidden');
  }

  openIfInvalid() {
    const hasInvalidInput = this.translatedFieldTargets.some(field => field.classList.contains('is-invalid'));
    if(hasInvalidInput) {
      this.toggleFields();
    }
  }
}
