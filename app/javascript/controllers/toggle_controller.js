import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]
  static values  = { show: Boolean }

  connect() {
    this.#update()
  }

  toggle(event) {
    this.showValue = event.target.checked
  }

  showValueChanged() {
    this.#update()
  }

  #update() {
    this.contentTargets.forEach(el => el.classList.toggle("hidden", !this.showValue))
  }
}
