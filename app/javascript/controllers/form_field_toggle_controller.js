import { Controller } from "@hotwired/stimulus";
import debounce from "lodash.debounce";

export default class extends Controller {
  static targets = ["toggle"];

  toggle(event) {
    const selected = event.target.options[event.target.options.selectedIndex];

    if (selected.dataset.visibility === "true") {
      this.toggleTarget.classList.remove("hidden");
    } else {
      this.toggleTarget.classList.add("hidden");
    }
  }
}
