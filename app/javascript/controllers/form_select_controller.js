import {Controller} from "@hotwired/stimulus";


export default class extends Controller {

  connect() {
    this.elementAdded(this.element)
  }

  elementAdded(element) {
    var app;

    app = window.App || (window.App = {});
    app.tomSelects = {};

    app.tomSelects[element.id] = new TomSelect(`#${element.id}`, {
      plugins: element.multiple ? ["remove_button"] : [],
      create: false,
      onItemAdd() {
        this.setTextboxValue("");
        if(!this.dropdown.classList.contains("single") ) {
          this.refreshOptions();
        }
      },
      render: {
        no_results() {
          // Render localized "no results" message
          const message = this.input.dataset.chosenNoResults || "No results found";
          return `<div class="no-results">${message}</div>`;
        },
      }
    });
  }
}
