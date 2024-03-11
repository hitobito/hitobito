import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["select", "toggle"];

  connect() {
    this.toggle()
  }

  toggle(event) {
    const selected = this.selectTarget.options[this.selectTarget.options.selectedIndex];

    if (selected.dataset.visibility === "true") {
      this.toggleTarget.classList.remove("hidden");
    } else {
      this.toggleTarget.classList.add("hidden");
    }
  }
}
