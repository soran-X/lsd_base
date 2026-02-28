import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "template"]

  add(event) {
    event.preventDefault()
    const index = Date.now()
    const html = this.templateTarget.innerHTML.replace(/__INDEX__/g, index)
    const tmp = document.createElement("div")
    tmp.innerHTML = html
    this.containerTarget.appendChild(tmp.firstElementChild)
  }

  remove(event) {
    event.preventDefault()
    const row = event.target.closest("[data-nested-form-row]")
    const idField = row.querySelector("input[name*='[id]']")
    if (idField?.value) {
      row.querySelector("input[name*='_destroy']").value = "1"
      row.classList.add("hidden")
    } else {
      row.remove()
    }
  }
}
