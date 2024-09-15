import debounce from "lodash.debounce";
import { Controller } from "@hotwired/stimulus";

// Currently (Sep '24) we are not able to import libraries using webpacker inside wagons.
// Therefore we place wagon stimulus controllers in core until webpacker is replaced.

export default class extends Controller {
  static targets = ["requiredLabel", "optionalLabel"];

  static values = {
    adultFrom: {
      type: Number,
    },
    emailValidationPath: {
      type: String,
    },
    delay: {
      type: Number,
      default: 150,
    },
  };

  initialize() {
    this.toggleFields = this.toggleFields.bind(this);
  }

  connect() {
    // necessary because datepicker still has prev value when focus is lost
    this.toggleFields = debounce(this.toggleFields, this.delayValue);
  }

  toggleFields(e) {
    const elem = e.srcElement;
    const birthday = moment(elem.value, ["dd.mm.yyyy", "dd/mm/yyyy"]);
    const adult = moment().year() - birthday.year() >= this.adultFromValue;
    if (adult) {
      this.optionalLabelTargets.forEach((e) => e.classList.add("d-none"));
      this.requiredLabelTargets.forEach((e) => e.classList.remove("d-none"));
    } else {
      this.requiredLabelTargets.forEach((e) => e.classList.add("d-none"));
      this.optionalLabelTargets.forEach((e) => e.classList.remove("d-none"));
    }
  }

  validateEmail(e) {
    const srcElement = e.srcElement;
    const formData = new FormData();
    formData.append("email", e.srcElement.value);
    formData.append("id", e.srcElement.id);
    fetch(this.emailValidationPathValue, {
      method: "POST",
      headers: {
        Accept: "application/json",
        "X-CSRF-Token": this.getCsrfToken(),
      },
      body: formData,
    })
      .then((r) => r.text())
      .then((text) => JSON.parse(text))
      .then(function (json) {
        srcElement.classList.remove("is-invalid");
        if (json.exists) {
          srcElement.classList.add("is-invalid");
        }
      });
  }

  // This is not set for test-env
  getCsrfToken() {
    if (document.querySelector('meta[name="csrf-token"]')) {
      return document.querySelector('meta[name="csrf-token"]').content;
    }
  }
}
