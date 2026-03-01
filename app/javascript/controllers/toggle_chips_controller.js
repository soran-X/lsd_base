import { Controller } from "@hotwired/stimulus"

/**
 * ToggleChipsController
 *
 * A row of pill buttons for toggling a fixed set of options.
 * Clicking a pill selects/deselects it and manages hidden inputs.
 *
 * Values:
 *   field-name – the form param name, e.g. "q[status][]"
 *
 * Each chip button must have:
 *   data-chip-value   – value submitted when selected
 *   data-selected     – "true" | "false" (pre-population from server)
 *   data-action       – "click->toggle-chips#toggle"
 */
export default class extends Controller {
  static targets = ["inputs"]
  static values  = { fieldName: String }

  connect() {
    this.ON  = "bg-indigo-600 text-white border-transparent shadow-sm"
    this.OFF = "bg-white text-gray-600 border-gray-200 hover:border-indigo-300 hover:text-indigo-600"

    this.element.querySelectorAll("[data-chip-value]").forEach(btn => {
      const isOn = btn.dataset.selected === "true"
      this._paint(btn, isOn)
      if (isOn) this._addInput(btn.dataset.chipValue)
    })
  }

  toggle(event) {
    const btn  = event.currentTarget
    const val  = btn.dataset.chipValue
    const isOn = btn.dataset.selected !== "true"   // flip

    btn.dataset.selected = isOn ? "true" : "false"
    this._paint(btn, isOn)

    if (isOn) {
      this._addInput(val)
    } else {
      this.inputsTarget.querySelector(`input[value="${val}"]`)?.remove()
    }
  }

  _addInput(val) {
    // Guard against duplicates
    if (this.inputsTarget.querySelector(`input[value="${val}"]`)) return
    const input  = document.createElement("input")
    input.type   = "hidden"
    input.name   = this.fieldNameValue
    input.value  = val
    this.inputsTarget.appendChild(input)
  }

  _paint(btn, isOn) {
    const add    = isOn ? this.ON  : this.OFF
    const remove = isOn ? this.OFF : this.ON
    remove.split(" ").forEach(c => c && btn.classList.remove(c))
    add.split(" ").forEach(c => c && btn.classList.add(c))
  }
}
