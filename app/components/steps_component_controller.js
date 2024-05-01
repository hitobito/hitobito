// frozen_string_literal: true
//
//  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
//  hitobito and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/hitobito/hitobito_sac_cas.

import { Controller } from "controllers";

export default class extends Controller {
  static targets = ["step", "stepContent", "stepHeader"];

  activate(event) {
    event.preventDefault();
    event.stopPropagation();
    const index = this.#getIndex(event.target.parentElement);
    this.#activateStep(index);
  }

  back(event) {
    event.preventDefault();
    const index = parseInt(event.target.dataset["index"]);
    this.#activateStep(index);
  }

  // internal methods
  #activateStep(index) {
    this.stepTarget.value = index;

    this.stepHeaderTargets.forEach((elem) => elem.classList.remove("active"));
    this.stepContentTargets.forEach((elem) => {
      elem.classList.remove("active");
      elem.querySelectorAll('button[type="submit"]').type = "button";
    });

    this.stepHeaderTargets[index].classList.add("active");
    this.stepContentTargets[index].classList.add("active");
    this.#getSubmitButton(this.stepContentTargets[index]).type = "submit";
  }

  #getIndex(element) {
    return Array.from(element.parentNode.children).indexOf(element);
  }

  #getSubmitButton(element) {
    return element.querySelector(".btn-toolbar button.btn-primary");
  }
}
