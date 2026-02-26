import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    requestAnimationFrame(() => {
      this.element.style.transition = "opacity 0.2s ease, transform 0.2s ease"
      this.element.style.opacity = "1"
      this.element.style.transform = "translateX(0)"
    })
    this.timeout = setTimeout(() => this.dismiss(), 5000)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  dismiss() {
    this.element.style.transition = "opacity 0.3s ease, transform 0.3s ease"
    this.element.style.opacity = "0"
    this.element.style.transform = "translateX(1rem)"
    setTimeout(() => this.element.remove(), 300)
  }
}
