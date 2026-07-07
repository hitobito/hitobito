// Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito

// Currently (Jul '26) we are not able to import libraries using webpacker inside wagons.
// Therefore we place wagon stimulus controllers in core until webpacker is replaced.

// This controller is used to filter technical requirment options in tour form
// based on selected event activities

import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["activities", "technicalRequirements"];
  static outlets = ["tom-select"];

  filter = () => {
    const activitiesTom = this.tomSelectFor(this.activitiesTarget);
    const technicalRequirementsTom = this.tomSelectFor(this.technicalRequirementsTarget);

    if (!activitiesTom || !technicalRequirementsTom) return;

    if (!this.allOptions) {
      this.allOptions = {...technicalRequirementsTom.options};
      this.allOptgroups = {...technicalRequirementsTom.optgroups};
    }

    const allowedGroupIds = this.allowedTechnicalRequirementIds(activitiesTom);

    technicalRequirementsTom.clearOptions();
    this.restoreAllowedOptgroups(technicalRequirementsTom, allowedGroupIds);
    this.restoreAllowedOptions(technicalRequirementsTom, allowedGroupIds);
    this.removeDisallowedSelections(technicalRequirementsTom, allowedGroupIds);

    technicalRequirementsTom.refreshOptions(false);
  };

  tomSelectFor(element) {
    return this.tomSelectOutlets.find((outlet) => outlet.element === element)?.tom;
  }

  allowedTechnicalRequirementIds(activitiesTom) {
    return activitiesTom
      .getValue()
      .map((id) => String(activitiesTom.options[id].technicalRequirementId));
  }

  restoreAllowedOptgroups(technicalRequirementsTom, allowedGroupIds) {
    Object.values(this.allOptgroups)
      .filter((optgroup) => allowedGroupIds.includes(String(optgroup.value)))
      .forEach((optgroup) => technicalRequirementsTom.addOptionGroup(optgroup.value, optgroup));
  }

  restoreAllowedOptions(technicalRequirementsTom, allowedGroupIds) {
    Object.values(this.allOptions)
      .filter((option) => allowedGroupIds.includes(String(option.group)))
      .forEach((option) => technicalRequirementsTom.addOption(option));
  }

  removeDisallowedSelections(technicalRequirementsTom, allowedGroupIds) {
    Object.keys(technicalRequirementsTom.options)
      .filter((id) => !allowedGroupIds.includes(String(technicalRequirementsTom.options[id].group)))
      .forEach((id) => {
        technicalRequirementsTom.removeItem(id, true);
        technicalRequirementsTom.removeOption(id, true);
      });
  }
}
