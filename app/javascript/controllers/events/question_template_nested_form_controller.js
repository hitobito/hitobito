import NestedFormController from "../nested_form_controller";

export default class extends NestedFormController {
  static targets = [...NestedFormController.targets, "questionTemplateFormTemplate"]

  addFromTemplate(e) {
    this.insertTemplate(this.questionTemplateFormTemplateTarget)
    this.fillTemplate(e)
  }

  fillTemplate(e) {
    const newFields = this.targetTarget.previousElementSibling
    const attributes = JSON.parse(e.target.dataset.templateAttributes || "{}")
    if (attributes.choices) {
      newFields.querySelector(".choices")?.classList.remove("d-none")
      const ul = newFields.querySelector(".choices ul")
      if (ul) {
        const choices = attributes.choices.split(",").map(c => c.replaceAll("\\u002C", ",").trim())
        ul.innerHTML = choices.map(c => `<li>${c}</li>`).join("")
      }
    }

    Object.entries(attributes).forEach(([name, value]) => {
      const field = newFields.querySelector(`[name*="[${name}]"]`)
      if (!field) return
      field.value = value
      if (name === "question") {
        const label = field.parentElement.querySelector("p")
        if (label) label.textContent = value
      }
      if (name === "multiple_choices") {
        newFields.querySelector('[data-multiple-choices-icon="true"]')?.classList.toggle("d-none", !value)
        newFields.querySelector('[data-multiple-choices-icon="false"]')?.classList.toggle("d-none", !!value)
      }
    })
  }

  get wrapperSelectorValue() {
    return `#${this.assocValue}_fields .fields`
  }
}
