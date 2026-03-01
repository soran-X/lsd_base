import { Controller } from "@hotwired/stimulus"

/**
 * StaticComboboxController
 *
 * Searchable multi-select combobox backed by a pre-loaded list of options
 * (no API calls — client-side filtering only). Mirrors the UX of
 * AuthorComboboxController but simpler: no fetch, no create.
 *
 * Values:
 *   options   – JSON array of {id, label} — all available choices
 *   selected  – JSON array of {id, label} — pre-selected on load (for show page)
 *   field-name – hidden input name, e.g. "q[genre_ids][]"
 */
export default class extends Controller {
  static targets = ["input", "dropdown", "list", "chips"]
  static values  = {
    options:    { type: Array,  default: [] },
    selected:   { type: Array,  default: [] },
    fieldName:  String
  }

  connect() {
    this.chosen        = new Map()   // id (number) → label
    this.visibleOpts   = []
    this.highlightIdx  = -1

    this._outsideClick = this._handleOutsideClick.bind(this)
    document.addEventListener("click", this._outsideClick)

    // Pre-populate from selectedValue (server-side saved params)
    this.selectedValue.forEach(item => {
      const id = isNaN(item.id) ? item.id : parseInt(item.id)
      this.chosen.set(id, item.label)
      this._renderChip({ id, label: item.label })
    })
  }

  disconnect() {
    document.removeEventListener("click", this._outsideClick)
  }

  // ── Input events ─────────────────────────────────────────────────────────

  onInput() {
    const q = this.inputTarget.value.trim().toLowerCase()
    this.visibleOpts = this.optionsValue
      .filter(o => !this.chosen.has(o.id) && o.label.toLowerCase().includes(q))
    this.highlightIdx = -1
    this._renderDropdown(q)
  }

  onFocus() {
    if (this._isClosed()) this.onInput()
  }

  onKeydown(event) {
    const items = this._listItems()
    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        if (this._isClosed()) { this.onInput(); break }
        this.highlightIdx = Math.min(this.highlightIdx + 1, items.length - 1)
        this._applyHighlight(items)
        break
      case "ArrowUp":
        event.preventDefault()
        this.highlightIdx = Math.max(this.highlightIdx - 1, 0)
        this._applyHighlight(items)
        break
      case "Enter":
        event.preventDefault()
        if (this.highlightIdx >= 0 && this.visibleOpts[this.highlightIdx]) {
          this._select(this.visibleOpts[this.highlightIdx])
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
      this.highlightIdx = idx
      this._applyHighlight(this._listItems())
    }
  }

  selectResult(event) {
    const idx = parseInt(event.currentTarget.dataset.comboboxIndex)
    if (!isNaN(idx) && this.visibleOpts[idx]) this._select(this.visibleOpts[idx])
  }

  removeChip(event) {
    const raw  = event.currentTarget.dataset.itemId
    // ids may be numeric or string (e.g. activity types like "ACQ")
    const id   = isNaN(raw) ? raw : parseInt(raw)
    const chip = this.chipsTarget.querySelector(`[data-item-id="${raw}"]`)
    this.chosen.delete(id)
    chip?.remove()
  }

  // ── Private ───────────────────────────────────────────────────────────────

  _select(item) {
    const id = isNaN(item.id) ? item.id : parseInt(item.id)
    if (this.chosen.has(id)) return
    this.chosen.set(id, item.label)
    this._renderChip({ id, label: item.label })
    this.inputTarget.value = ""
    this._close()
    this.inputTarget.focus()
  }

  _renderChip(item) {
    const chip = document.createElement("div")
    chip.className =
      "inline-flex items-center gap-2 pl-3 pr-2 py-1.5 rounded-full text-sm font-medium " +
      "bg-indigo-50 text-indigo-800 border border-indigo-200"
    chip.dataset.itemId = item.id
    chip.innerHTML = `
      <span>${item.label}</span>
      <input type="hidden" name="${this.fieldNameValue}" value="${item.id}">
      <button type="button"
              data-item-id="${item.id}"
              data-action="click->static-combobox#removeChip"
              title="Remove"
              class="rounded-full p-0.5 hover:bg-indigo-200 text-indigo-400
                     hover:text-indigo-700 transition-colors">
        <svg class="w-3.5 h-3.5" viewBox="0 0 20 20" fill="currentColor">
          <path d="M6.28 5.22a.75.75 0 00-1.06 1.06L8.94 10l-2.72 2.72a.75.75 0
                   101.06 1.06L10 11.06l2.72 2.72a.75.75 0 101.06-1.06L11.06 10l2.72-2.72a.75.75
                   0 00-1.06-1.06L10 8.94 6.28 5.22z"/>
        </svg>
      </button>
    `
    this.chipsTarget.appendChild(chip)
  }

  _renderDropdown(q) {
    if (!this.visibleOpts.length) {
      this.listTarget.innerHTML =
        '<li class="px-4 py-3 text-sm text-gray-400 italic">No matches.</li>'
      this._open()
      return
    }

    this.listTarget.innerHTML = this.visibleOpts.map((o, i) => `
      <li role="option"
          data-combobox-index="${i}"
          data-action="click->static-combobox#selectResult mouseenter->static-combobox#highlight"
          class="px-4 py-2.5 cursor-pointer text-sm text-gray-800 transition-colors duration-75"
          aria-selected="false">
        ${this._highlight(o.label, q)}
      </li>
    `).join("")
    this._open()
  }

  _open() {
    this.dropdownTarget.classList.remove("hidden")
    this.dropdownTarget.removeAttribute("hidden")
  }

  _close() {
    this.dropdownTarget.classList.add("hidden")
    this.dropdownTarget.setAttribute("hidden", "")
    this.highlightIdx = -1
    this.visibleOpts  = []
  }

  _isClosed() { return this.dropdownTarget.classList.contains("hidden") }
  _listItems() { return Array.from(this.listTarget.querySelectorAll("[data-combobox-index]")) }

  _applyHighlight(items) {
    items.forEach((item, i) => {
      const on = i === this.highlightIdx
      item.classList.toggle("bg-indigo-50",  on)
      item.classList.toggle("text-indigo-900", on)
      item.setAttribute("aria-selected", on)
    })
  }

  _highlight(label, q) {
    if (!q) return label
    const esc = q.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
    return label.replace(new RegExp(`(${esc})`, "gi"),
      '<strong class="font-semibold text-indigo-700">$1</strong>')
  }

  _handleOutsideClick(e) {
    if (!this.element.contains(e.target)) this._close()
  }
}
