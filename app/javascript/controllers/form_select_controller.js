import {Controller} from "@hotwired/stimulus";


export default class extends Controller {

  connect() {
    this.elementAdded(this.element)
  }

  elementAdded(element) {
    var app;

    app = window.App || (window.App = {});
    app.tomSelects = {};

    if(getComputedStyle(element.parentElement.parentElement.parentElement).display !== 'none') {
      app.tomSelects[element.id] = new TomSelect(`#${element.id}`, {
        plugins: element.multiple ? ["remove_button"] : [],
        create: false,
        onItemAdd() {
          this.setTextboxValue("");
        },
      });
    }
  }
}
