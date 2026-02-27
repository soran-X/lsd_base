import { Controller } from "@hotwired/stimulus"

/**
 * TabController
 *
 * Simple, accessible tab switcher with optional localStorage persistence.
 *
 * Usage:
 *   data-controller="tab"
 *   data-tab-persist-value="book-form-tabs"   ← localStorage key (optional)
 *
 * Tabs (buttons):
 *   data-tab-target="tab"
 *   data-tab="info"
 *   data-action="click->tab#switch"
 *
 * Panels:
 *   data-tab-target="panel"
 *   data-tab="info"
 */
export default class extends Controller {
  static targets = ["tab", "panel"]
  static values  = {
    persist: { type: String, default: "" }
  }

  connect() {
    const saved  = this.persistValue ? localStorage.getItem(this.persistValue) : null
    const first  = this.tabTargets[0]?.dataset.tab
    const exists = name => this.tabTargets.some(t => t.dataset.tab === name)

    this._activate(exists(saved) ? saved : first)
  }

  switch(event) {
    const name = event.currentTarget.dataset.tab
    this._activate(name)
    if (this.persistValue) localStorage.setItem(this.persistValue, name)
  }

  _activate(name) {
    this.tabTargets.forEach(tab => {
      const on = tab.dataset.tab === name
      tab.setAttribute("aria-selected", on)
      // Active state
      tab.classList.toggle("border-indigo-600",  on)
      tab.classList.toggle("text-indigo-700",    on)
      tab.classList.toggle("font-semibold",      on)
      // Inactive state
      tab.classList.toggle("border-transparent", !on)
      tab.classList.toggle("text-gray-500",      !on)
      tab.classList.toggle("hover:text-gray-700",     !on)
      tab.classList.toggle("hover:border-gray-300",   !on)
    })

    this.panelTargets.forEach(panel => {
      const on = panel.dataset.tab === name
      panel.classList.toggle("hidden", !on)
    })
  }
}
