// frozen_string_literal: true
//
//  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
//  hitobito and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/hitobito/hitobito_sac_cas.

import { Controller } from "controllers";

export default class extends Controller {
  activate(event) {
    event.preventDefault();
    event.stopPropagation();
    const index = this.getIndex(event.target.parentElement);
    this.activateStep(index);
  }

  activateStep(index) {
    const headers = Array.from(
      this.element.querySelectorAll("ol.step-headers li")
    );
    const contents = Array.from(this.element.querySelectorAll(".step-content"));

    headers.forEach((elem) => elem.classList.remove("active"));
    contents.forEach((elem) => {
      elem.classList.remove("active");
      elem.querySelectorAll('button[type="submit"]').type = "button";
    });

    headers[index].classList.add("active");
    contents[index].classList.add("active");
    this.getSubmitButton(contents[index]).type = "submit";
  }

  getIndex(element) {
    return Array.from(element.parentNode.children).indexOf(element);
  }

  getCurrentIndex() {
    return this.getIndex(document.querySelector("li.active"));
  }

  getAmountOfSteps() {
    return Array.from(document.querySelectorAll("ol.step-headers li")).length;
  }

  getSubmitButton(element) {
    return element.querySelector(".btn-toolbar button.btn-primary");
  }

  back(event) {
    event.preventDefault();
    const index = parseInt(event.target.dataset["index"]);
    this.activateStep(index);
  }
}
