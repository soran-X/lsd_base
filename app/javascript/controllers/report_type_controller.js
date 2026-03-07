import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select", "standardBooks", "customArea", "customTemplateIdField"]

  connect() {
    this.syncVisibility()
  }

  onChange() {
    this.syncVisibility()
  }

  syncVisibility() {
    if (!this.hasSelectTarget) return

    const val = this.selectTarget.value

    if (val.startsWith("custom:")) {
      const templateId = val.split(":")[1]

      // Update hidden field
      if (this.hasCustomTemplateIdFieldTarget) {
        this.customTemplateIdFieldTarget.value = templateId
      }

      // Hide standard books
      if (this.hasStandardBooksTarget) {
        this.standardBooksTarget.classList.add("hidden")
      }

      // Show matching custom area, hide others
      this.customAreaTargets.forEach(area => {
        if (area.dataset.templateId === templateId) {
          area.classList.remove("hidden")
        } else {
          area.classList.add("hidden")
        }
      })
    } else {
      // Clear hidden field
      if (this.hasCustomTemplateIdFieldTarget) {
        this.customTemplateIdFieldTarget.value = ""
      }

      // Show standard books
      if (this.hasStandardBooksTarget) {
        this.standardBooksTarget.classList.remove("hidden")
      }

      // Hide all custom areas
      this.customAreaTargets.forEach(area => area.classList.add("hidden"))
    }
  }
}
