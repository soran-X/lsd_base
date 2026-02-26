import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  run() {
    if (this._pending) return
    this._pending = true
    setTimeout(() => { this._pending = false }, 2000)

    const csrf = document.querySelector("meta[name='csrf-token']")?.content
    fetch(this.urlValue, { method: "POST", headers: { "X-CSRF-Token": csrf } })
  }
}
