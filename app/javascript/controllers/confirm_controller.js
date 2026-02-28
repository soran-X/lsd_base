import { Controller } from "@hotwired/stimulus"

/**
 * ConfirmController
 *
 * Replaces the native browser confirm() dialog with a themed <dialog> modal.
 * Attach this controller high in the DOM (e.g. <body>) so it can be reached
 * from any delete button via Stimulus event delegation.
 *
 * Targets:
 *   dialog  – the <dialog> element
 *   message – element where the confirmation message is written
 *
 * Usage on any delete button:
 *   data-action="click->confirm#open"
 *   data-confirm-message-param="Delete 'Foo'?"
 */
export default class extends Controller {
  static targets = ["dialog", "message"]

  open(event) {
    event.preventDefault()
    this._pending = event.currentTarget.closest("form")
    this.messageTarget.textContent = event.params.message || "Are you sure?"
    this.dialogTarget.showModal()
  }

  submit() {
    this.dialogTarget.close()
    if (this._pending) {
      this._pending.requestSubmit()
      this._pending = null
    }
  }

  cancel() {
    this.dialogTarget.close()
    this._pending = null
  }
}
