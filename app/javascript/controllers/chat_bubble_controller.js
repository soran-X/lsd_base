import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["window", "frame", "button"]

  connect() {
    this.loaded = false
  }

  open() {
    this.windowTarget.classList.remove("hidden")
    this.buttonTarget.classList.add("hidden")

    if (!this.loaded) {
      this.frameTarget.src = this.frameTarget.dataset.src
      this.loaded = true
    }
  }

  close() {
    this.windowTarget.classList.add("hidden")
    this.buttonTarget.classList.remove("hidden")
  }
}
