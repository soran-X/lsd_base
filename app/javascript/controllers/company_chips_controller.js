import { Controller } from "@hotwired/stimulus"

/**
 * CompanyChipsController
 *
 * Multi-select search combobox for picking existing companies (chip tags).
 *
 * Values:
 *   search-url  – URL for GET search endpoint (returns [{id, label}])
 *   field-name  – Hidden input name, e.g. "book[agency_company_ids][]"
 */
export default class extends Controller {
  static targets = ["input", "dropdown", "list", "chips"]
  static values  = {
    searchUrl: String,
    fieldName: String
  }

  connect() {
    this.selected       = new Map()
    this.results        = []
    this.highlightIndex = -1
    this.debounceTimer  = null
    this.abort          = null

    this._outsideClick = this._handleOutsideClick.bind(this)
    document.addEventListener("click", this._outsideClick)

    // Pre-populate from server-rendered chips
    this.chipsTarget.querySelectorAll("[data-company-id]").forEach(chip => {
      this.selected.set(parseInt(chip.dataset.companyId), chip.dataset.companyLabel)
    })
  }

  disconnect() {
    document.removeEventListener("click", this._outsideClick)
    if (this.abort) this.abort.abort()
    clearTimeout(this.debounceTimer)
  }

  // ── Input events ─────────────────────────────────────────────────────────

  onInput() {
    const q = this.inputTarget.value.trim()
    clearTimeout(this.debounceTimer)
    if (q.length === 0) { this._close(); return }
    this.debounceTimer = setTimeout(() => this._search(q), 200)
  }

  onKeydown(event) {
    if (this._isClosed()) {
      if (event.key === "ArrowDown") { event.preventDefault(); this._open() }
      return
    }
    const items = this._listItems()
    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        this.highlightIndex = Math.min(this.highlightIndex + 1, items.length - 1)
        this._applyHighlight(items)
        break
      case "ArrowUp":
        event.preventDefault()
        this.highlightIndex = Math.max(this.highlightIndex - 1, 0)
        this._applyHighlight(items)
        break
      case "Enter":
        event.preventDefault()
        if (this.highlightIndex >= 0 && this.results[this.highlightIndex]) {
          this._select(this.results[this.highlightIndex])
        }
        break
      case "Escape":
        this._close()
        this.inputTarget.value = ""
        break
    }
  }

  highlight(event) {
    const idx = parseInt(event.currentTarget.dataset.comboboxIndex)
    if (!isNaN(idx)) {
      this.highlightIndex = idx
      this._applyHighlight(this._listItems())
    }
  }

  selectResult(event) {
    const idx = parseInt(event.currentTarget.dataset.comboboxIndex)
    if (!isNaN(idx) && this.results[idx]) this._select(this.results[idx])
  }

  removeChip(event) {
    const id   = parseInt(event.currentTarget.dataset.companyId)
    const chip = this.chipsTarget.querySelector(`[data-company-id="${id}"]`)
    this.selected.delete(id)
    chip?.remove()
  }

  // ── Private ───────────────────────────────────────────────────────────────

  async _search(query) {
    if (this.abort) this.abort.abort()
    this.abort = new AbortController()

    try {
      const url = new URL(this.searchUrlValue, window.location.origin)
      url.searchParams.set("q", query)
      const res = await fetch(url, {
        signal:  this.abort.signal,
        headers: { "Accept": "application/json" }
      })
      if (!res.ok) return
      const all    = await res.json()
      this.results = all.filter(c => !this.selected.has(c.id))
      this._renderDropdown(query)
    } catch (e) {
      if (e.name !== "AbortError") console.error("Company chips search error:", e)
    }
  }

  _renderDropdown(query) {
    if (!this.results.length) {
      this.listTarget.innerHTML =
        '<li class="px-4 py-3 text-sm text-gray-400 italic">No companies found.</li>'
      this._open()
      return
    }

    this.listTarget.innerHTML = this.results.map((c, i) => `
      <li role="option"
          data-combobox-index="${i}"
          data-action="click->company-chips#selectResult mouseenter->company-chips#highlight"
          class="px-4 py-2.5 cursor-pointer flex items-center gap-3 text-sm transition-colors duration-75"
          aria-selected="false">
        <span>${this._highlight(c.label, query)}</span>
      </li>
    `).join("")
    this.highlightIndex = -1
    this._open()
  }

  _select(company) {
    if (this.selected.has(company.id)) return
    this.selected.set(company.id, company.label)
    this._addChip(company)
    this.inputTarget.value = ""
    this._close()
    this.inputTarget.focus()
  }

  _addChip(company) {
    const chip = document.createElement("div")
    chip.className =
      "inline-flex items-center gap-2 pl-3 pr-2 py-1.5 rounded-full text-sm font-medium " +
      "bg-sky-50 text-sky-800 border border-sky-200"
    chip.dataset.companyId    = company.id
    chip.dataset.companyLabel = company.label
    chip.innerHTML = `
      <span>${company.label}</span>
      <input type="hidden" name="${this.fieldNameValue}" value="${company.id}">
      <button type="button"
              data-company-id="${company.id}"
              data-action="click->company-chips#removeChip"
              title="Remove"
              class="rounded-full p-0.5 hover:bg-sky-200 text-sky-400 hover:text-sky-700 transition-colors">
        <svg class="w-3.5 h-3.5" viewBox="0 0 20 20" fill="currentColor">
          <path d="M6.28 5.22a.75.75 0 00-1.06 1.06L8.94 10l-2.72 2.72a.75.75 0
                   101.06 1.06L10 11.06l2.72 2.72a.75.75 0 101.06-1.06L11.06 10l2.72-2.72a.75.75
                   0 00-1.06-1.06L10 8.94 6.28 5.22z"/>
        </svg>
      </button>
    `
    this.chipsTarget.appendChild(chip)
  }

  _open()  {
    this.dropdownTarget.classList.remove("hidden")
    this.dropdownTarget.removeAttribute("hidden")
  }
  _close() {
    this.dropdownTarget.classList.add("hidden")
    this.dropdownTarget.setAttribute("hidden", "")
    this.highlightIndex = -1
    this.results = []
  }
  _isClosed() { return this.dropdownTarget.classList.contains("hidden") }
  _listItems() { return Array.from(this.listTarget.querySelectorAll("[data-combobox-index]")) }

  _applyHighlight(items) {
    items.forEach((item, i) => {
      const on = i === this.highlightIndex
      item.classList.toggle("bg-indigo-50", on)
      item.classList.toggle("text-indigo-900", on)
      item.setAttribute("aria-selected", on)
    })
  }

  _highlight(label, query) {
    if (!query) return label
    const esc = query.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
    return label.replace(new RegExp(`(${esc})`, "gi"),
      '<strong class="font-semibold text-indigo-700">$1</strong>')
  }

  _handleOutsideClick(e) {
    if (!this.element.contains(e.target)) this._close()
  }
}
