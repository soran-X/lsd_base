import { Controller } from "@hotwired/stimulus"

const CHOICE_TYPES = ["combobox", "multi_combobox"]

export default class extends Controller {
  static targets = ["choicesSection", "typeSelect"]

  connect() {
    this.toggleChoices()
  }

  typeChanged() {
    this.toggleChoices()
  }

  toggleChoices() {
    if (!this.hasChoicesSectionTarget || !this.hasTypeSelectTarget) return
    const type = this.typeSelectTarget.value
    if (CHOICE_TYPES.includes(type)) {
      this.choicesSectionTarget.classList.remove("hidden")
    } else {
      this.choicesSectionTarget.classList.add("hidden")
    }
  }
}
