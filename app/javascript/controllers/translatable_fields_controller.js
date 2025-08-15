import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ['toggle', 'translatedField', 'translatedFieldsDisplay']

  connect() {
    this.updateTranslatedFields();
    this.openIfInvalid();
  }

  updateTranslatedFields() {
    const translatedLanguages = this.translatedFieldTargets.map(translatedField => {
      if(translatedField.value) {
        const id_components = translatedField.id.split('_');
        return id_components[id_components.length - 1].toUpperCase();
      }
    }).filter(v => v)

    if(translatedLanguages.length > 0) {
      this.translatedFieldsDisplayTarget.textContent = `+ ${translatedLanguages.join(', ')}`;
    } else {
      this.translatedFieldsDisplayTarget.textContent = '-';
    }
  }

  toggleFields() {
    this.toggleTarget.classList.toggle('hidden');
  }

  openIfInvalid() {
    const hasInvalidInput = this.translatedFieldTargets.some(field => field.classList.contains('is-invalid'));
    if(hasInvalidInput) {
      this.toggleFields();
    }
  }
}
