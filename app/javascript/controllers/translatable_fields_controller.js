//  Copyright (c) 2012-2025, Puzzle ITC. This file is part of
//  hitobito and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/hitobito/hitobito.

import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ['toggle', 'translatedField', 'translatedFieldsDisplay', 'localeIndicator']
  static values = {
    additionalLanguagesText: String
  }

  connect() {
    this.updateTranslatedFields();
    this.openIfInvalid();
    this.setLocaleIndicatorWidth();
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

  // Sets the width of the input-group-text elements so they all have the same width
  setLocaleIndicatorWidth() {
    // This is needed because elements with display: none have width 0
    const parentTab = this.localeIndicatorTargets[0].closest(".tab-content > .tab-pane")
    if(parentTab) {
      parentTab.style.display = "block";
    }
    const indicatorWidths = this.localeIndicatorTargets.map(e => e.getBoundingClientRect().width);
    if(parentTab) {
      parentTab.style.display = "";
    }
    const indicatorMaxWidth = Math.max(...indicatorWidths)
    this.localeIndicatorTargets.forEach(e => e.style.width = `${indicatorMaxWidth}px`)
  }
}
