import { Controller } from "@hotwired/stimulus"

/**
 * ContactComboboxController
 *
 * Single-select search combobox for picking an existing contact.
 *
 * Values:
 *   url – search endpoint, e.g. "/contacts/search.json"
 *
 * Targets:
 *   input       – visible text input for searching / showing selection
 *   hiddenField – hidden input that holds the selected contact ID
 *   dropdown    – container for search results
 */
export default class extends Controller {
  static targets = ["input", "hiddenField", "dropdown"]
  static values  = { url: String }

  connect() {
    this._results      = []
    this._timer        = null
    this._abort        = null
    this._outsideClick = this._handleOutsideClick.bind(this)
    document.addEventListener("click", this._outsideClick)
  }

  disconnect() {
    document.removeEventListener("click", this._outsideClick)
    if (this._abort) this._abort.abort()
    clearTimeout(this._timer)
  }

  // ── Input events ─────────────────────────────────────────────────────────

  search() {
    clearTimeout(this._timer)
    const q = this.inputTarget.value.trim()
    if (q.length < 1) { this._close(); return }
    this._timer = setTimeout(() => this._fetch(q), 200)
  }

  onKeydown(event) {
    switch (event.key) {
      case "Escape":
        this._close()
        break
      case "Enter":
        event.preventDefault()
        if (this._results.length) this._select(this._results[0])
        break
    }
  }

  clear() {
    this.hiddenFieldTarget.value = ""
    this.inputTarget.value = ""
    this._close()
    this.inputTarget.focus()
  }

  // ── Private ───────────────────────────────────────────────────────────────

  async _fetch(q) {
    if (this._abort) this._abort.abort()
    this._abort = new AbortController()

    try {
      const url = new URL(this.urlValue, window.location.origin)
      url.searchParams.set("q", q)
      const res = await fetch(url, {
        signal:  this._abort.signal,
        headers: { "Accept": "application/json" }
      })
      if (!res.ok) return
      this._results = await res.json()
      this._render(q)
    } catch (e) {
      if (e.name !== "AbortError") console.error("Contact search error:", e)
    }
  }

  _render(query) {
    if (!this._results.length) {
      this.dropdownTarget.innerHTML =
        '<p class="px-4 py-3 text-sm text-gray-400 italic">No contacts found.</p>'
      this._open()
      return
    }

    this.dropdownTarget.innerHTML = ""
    this._results.forEach(item => {
      const btn = document.createElement("button")
      btn.type = "button"
      btn.className =
        "w-full text-left px-4 py-2.5 text-sm text-gray-800 hover:bg-indigo-50 transition-colors"
      btn.innerHTML = this._highlight(item.label, query)
      btn.addEventListener("click", (e) => {
        e.preventDefault()
        this._select(item)
      })
      this.dropdownTarget.appendChild(btn)
    })

    this._open()
  }

  _select(item) {
    this.hiddenFieldTarget.value = item.id
    this.inputTarget.value       = item.label
    this._close()
  }

  _open()  { this.dropdownTarget.classList.remove("hidden") }
  _close() { this.dropdownTarget.classList.add("hidden") }

  _highlight(label, query) {
    const esc = query.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
    return label.replace(
      new RegExp(`(${esc})`, "gi"),
      '<strong class="font-semibold text-indigo-700">$1</strong>'
    )
  }

  _handleOutsideClick(e) {
    if (!this.element.contains(e.target)) this._close()
  }
}
