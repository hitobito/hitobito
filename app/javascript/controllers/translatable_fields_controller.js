import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ['translatedField']

  connect() {
    this.updateTranslatedFields();
  }

  updateTranslatedFields() {
    const translatedLanguages =  this.translatedFieldTargets.map(translatedField => {
      if(translatedField.value) {
        const id_components = translatedField.id.split('_');
        return id_components[id_components.length - 1].toUpperCase();
      }
    }).filter(v => v !== undefined)
    document.getElementById('translated-fields').textContent = `+ ${translatedLanguages.join(', ')}`
  }
}
