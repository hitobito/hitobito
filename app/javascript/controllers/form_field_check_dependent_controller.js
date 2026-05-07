// Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito
//
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["main", "dependent"];
  static values = {
    interactionMode: { type: String, default: "default" },
    selectDependentCheckboxes: { type: Boolean, default: false }
  }

  toggleMain(event) {
    const isChecked = event.target.checked;

    if (this.interactionModeValue === "exclusive") {
      if (isChecked) {
        this.dependentTargets.forEach(cb => cb.checked = false);
      }
    } else {
      if (!isChecked) {
        this.dependentTargets.forEach(cb => cb.checked = false);
      } else if (this.selectDependentCheckboxesValue) {
        this.dependentTargets.forEach(cb => cb.checked = true);
      }
    }
  }

  toggleDependent(event) {
    const isChecked = event.target.checked;

    if (this.interactionModeValue === "exclusive") {
      if (isChecked && this.hasMainTarget) {
        this.mainTarget.checked = false;
      }
    } else {
      if (this.hasMainTarget) {
        this.mainTarget.checked = true;
      }
    }
  }
}