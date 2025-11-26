//  Copyright (c) 2012-2025, Puzzle ITC. This file is part of
//  hitobito and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/hitobito/hitobito.

import { Controller } from "@hotwired/stimulus";

/**
 * Stimulus controller for managing globalized (multilingual) input fields.
 * Handles the progressive disclosure UI that allows users to fill in translated
 * content in multiple languages, with the current locale always visible and
 * additional languages shown/hidden via a toggle button.
 */
export default class extends Controller {
  static targets = ['toggle', 'globalizedField', 'globalizedFieldsDisplay', 'localeIndicator']
  static values = {
    additionalLanguagesText: String
  }

  /**
   * Initializes the display by showing filled languages, auto-expanding if there
   * are validation errors, and ensuring consistent locale indicator widths.
   */
  connect() {
    this.updateGlobalizedFieldsDisplay();
    this.openIfInvalid();
    this.localeIndicatorTargets[0].classList.add('d-none')
  }

  /**
   * Updates the display text showing which additional languages have been filled in.
   * Extracts the language code from each field's ID and displays them as a comma-separated
   * list (e.g., "Zusätzlich ausgefüllte Sprachen: EN, FR").
   *
   * Called automatically on connect and whenever a globalized field value changes.
   */
  updateGlobalizedFieldsDisplay() {
    const filledOutLanguages = this.globalizedFieldTargets.map(globalizedField => {
      if(globalizedField.value) {
        const id_components = globalizedField.id.split('_');
        return id_components[id_components.length - 1].toUpperCase();
      }
    }).filter(v => v)

    if(filledOutLanguages.length > 0) {
      this.globalizedFieldsDisplayTarget.classList.remove('d-none')
      this.globalizedFieldsDisplayTarget.textContent = `${this.additionalLanguagesTextValue}: ${filledOutLanguages.join(', ')}`;
    } else {
      this.globalizedFieldsDisplayTarget.classList.add('d-none')
      this.globalizedFieldsDisplayTarget.textContent = '';
    }
  }

  /**
   * Toggles the visibility of additional language input fields.
   * Called when the user clicks the language toggle button (🌐 icon).
   * Adds/removes the 'hidden' class to show or hide the collapsible section.
   */
  toggleFields() {
    this.toggleTarget.classList.toggle('hidden');
    this.localeIndicatorTargets[0].classList.toggle('d-none');
  }

  /**
   * Automatically expands the additional language fields if any of them have
   * validation errors. This ensures users see invalid fields without having to
   * manually expand the section.
   */
  openIfInvalid() {
    const hasInvalidInput = this.globalizedFieldTargets.some(field => field.classList.contains('is-invalid'));
    if(hasInvalidInput) {
      this.toggleFields();
    }
  }
}
