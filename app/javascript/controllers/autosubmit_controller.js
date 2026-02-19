// Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito

import { Controller } from "@hotwired/stimulus";
import debounce from "lodash.debounce";

export default class extends Controller {
  static values = {
    delay: {
      type: Number,
      default: 150,
    },
  };

  initialize() {
    this.save = this.save.bind(this);
  }

  connect() {
    if (this.delayValue > 0) {
      this.save = debounce(this.save, this.delayValue);
    }
  }

  clear() {
    const elem = this.element.querySelector("[data-action='autosubmit#save']");
    if(elem) {
      elem.value = "";
      this.element.requestSubmit();
    }
  }

  save(event) {
    const submit = document.querySelector("input[name=autosubmit]");
    this.#withAutosubmitValue(submit, event.target.name || "autosubmit", () => {
      this.#withTurboFrame(event.target.dataset.turboFrame, () => {
        this.element.requestSubmit();
      })
    })
  }

  /**
   * In autosubmitted requests, we want to send along a parameter autosubmit=something, so that
   * the server can identify that this is an autosubmit request. For this to work, a hidden
   * "autosubmit" field must be present in the form. #withAutosubmitValue will temporarily
   * override the value of that hidden field during autosubmit requests.
   */
  #withAutosubmitValue(autosubmitElement, value, callback) {
    if (!autosubmitElement || !value) return callback();
    const previous = autosubmitElement.value;
    autosubmitElement.value = value;
    callback();
    autosubmitElement.value = previous;
  }

  /**
   * In some cases, we want to specify a data-turbo-frame on the form during autosubmits,
   * but not (or with a different data-turbo-frame value) during normal submits. This
   * is the case when the form is both used normally for submitting CRUD requests, but also
   * some inputs should trigger a partial reload of the form (because some other fields might
   * depend on the values in the previous fields). In that case, we can specify the
   * data-turbo-frame value on the element triggering the autosubmit#save action.
   */
  #withTurboFrame(turboFrameId, callback) {
    if (!turboFrameId) return callback();
    const previous = this.element.dataset.turboFrame;
    this.element.dataset.turboFrame = turboFrameId;
    callback();
    this.element.dataset.turboFrame = previous;
  }
}
