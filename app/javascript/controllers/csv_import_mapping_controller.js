//  Copyright (c) 2026, Puzzle ITC. This file is part of
//  hitobito and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/hitobito/hitobito

import { Controller } from "@hotwired/stimulus";

const STORAGE_KEY = "csv_import_field_mappings";

// Used on the CSV person import's column mapping page (define_mapping)
// to persist the CSV column -> field mapping in localStorage as
// { "<csv-header>": "<field_key>" } so it can be reused for subsequent
// imports of files with identical headers.
// Priority when applying: params (previously chosen mapping) >
// localStorage > PersonColumnGuesser suggestion.
export default class extends Controller {
  static targets = ["select"];

  // On connect, applies the stored localStorage mapping to each select:
  // selects that already carry a value from params (data-from-params)
  // are left untouched; for the rest the stored field key is applied —
  // but only if it is still a valid option (e.g. `id` is not offered to
  // non-admin users, so the guesser's suggestion stays in that case).
  connect() {
    const stored = this.#storedMappings();
    this.selectTargets.forEach((select) => {
      if (select.dataset.fromParams === "true") return;

      const fieldKey = stored[select.dataset.header];
      if (fieldKey && this.#optionExists(select, fieldKey)) {
        select.value = fieldKey;
      }
    });
  }

  // Merge semantics (triggered on every change of a mapping select):
  // only mappings for headers present in the current file are
  // added/updated, mappings for other headers are kept.
  save() {
    const stored = this.#storedMappings();
    this.selectTargets.forEach((select) => {
      stored[select.dataset.header] = select.value;
    });
    localStorage.setItem(STORAGE_KEY, JSON.stringify(stored));
  }

  #storedMappings() {
    try {
      return JSON.parse(localStorage.getItem(STORAGE_KEY)) || {};
    } catch {
      return {};
    }
  }

  #optionExists(select, value) {
    return Array.from(select.options).some((option) => option.value === value);
  }
}
