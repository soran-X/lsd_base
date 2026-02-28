import { Controller } from "@hotwired/stimulus"

/**
 * AuthorComboboxController
 *
 * A zero-dependency, keyboard-accessible combobox for author selection.
 *
 * Features:
 *  - Debounced live search via pg_search trigrams (200 ms)
 *  - In-flight request cancellation via AbortController
 *  - Keyboard navigation (↑ ↓ Enter Esc)
 *  - "LastName, FirstName" input parsing
 *  - Inline async author creation (no page reload)
 *  - Chip tags with × removal
 *  - Pre-populated on edit forms
 *  - Outside-click dismissal
 *
 * Values:
 *   search-url  – URL for GET search endpoint (returns [{id, label}])
 *   create-url  – URL for POST create endpoint (returns {id, label})
 *   field-name  – Hidden input name, e.g. "book[author_ids][]"
 *   role        – Display label: "Author" | "Translator"
 */
export default class extends Controller {
  static targets = ["input", "dropdown", "list", "chips", "spinner"]
  static values  = {
    searchUrl:  String,
    createUrl:  String,
    fieldName:  String,
    role:       { type: String, default: "Author" },
    chipCls:    { type: String, default: "bg-indigo-50 text-indigo-800 border border-indigo-200" },
    btnCls:     { type: String, default: "hover:bg-indigo-200 text-indigo-400 hover:text-indigo-700 focus:ring-indigo-400" }

  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  connect() {
    this.selected       = new Map()   // id → label
    this.results        = []
    this.highlightIndex = -1
    this.debounceTimer  = null
    this.abort          = null

    this._outsideClick = this._handleOutsideClick.bind(this)
    document.addEventListener("click", this._outsideClick)

    // Pre-populate existing selections rendered as data attributes on chips
    this.chipsTarget.querySelectorAll("[data-author-id]").forEach(chip => {
      const id    = parseInt(chip.dataset.authorId)
      const label = chip.dataset.authorLabel
      this.selected.set(id, label)
    })
  }

  disconnect() {
    document.removeEventListener("click", this._outsideClick)
    if (this.abort) this.abort.abort()
    clearTimeout(this.debounceTimer)
  }

  // ── Input events ───────────────────────────────────────────────────────────

  onInput() {
    const q = this.inputTarget.value.trim()
    clearTimeout(this.debounceTimer)

    if (q.length === 0) { this._close(); return }

    this.debounceTimer = setTimeout(() => this._search(q), 200)
  }

  onKeydown(event) {
    if (this._isClosedDropdown()) {
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

  // ── Result actions ─────────────────────────────────────────────────────────

  selectResult(event) {
    const idx = parseInt(event.currentTarget.dataset.comboboxIndex)
    if (!isNaN(idx) && this.results[idx]) this._select(this.results[idx])
  }

  async createAuthor(event) {
    const query = this.inputTarget.value.trim()
    const { firstName, lastName } = this._parseName(query)

    if (!lastName) return

    const label = [lastName, firstName].filter(Boolean).join(", ")
    if (!confirm(`Create new ${this.roleValue.toLowerCase()} "${label}"?`)) return

    this._setLoading(true)

    try {
      const res = await fetch(this.createUrlValue, {
        method:  "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept":       "application/json",
          "X-CSRF-Token": this._csrfToken()
        },
        body: JSON.stringify({ author: { first_name: firstName, last_name: lastName } })
      })

      if (res.ok) {
        const author = await res.json()
        this._select(author)
      } else {
        const errors = await res.json()
        alert(`Could not create author: ${Object.values(errors).flat().join(", ")}`)
      }
    } catch (e) {
      console.error("Author create failed:", e)
    } finally {
      this._setLoading(false)
    }
  }

  removeChip(event) {
    const id   = parseInt(event.currentTarget.dataset.authorId)
    const chip = this.chipsTarget.querySelector(`[data-author-id="${id}"]`)
    this.selected.delete(id)
    chip?.remove()
  }

  // ── Private ────────────────────────────────────────────────────────────────

  async _search(query) {
    if (this.abort) this.abort.abort()
    this.abort = new AbortController()
    this._setLoading(true)

    try {
      const url = new URL(this.searchUrlValue, window.location.origin)
      url.searchParams.set("q", query)

      const res = await fetch(url, {
        signal:  this.abort.signal,
        headers: { "Accept": "application/json" }
      })

      if (!res.ok) return

      const all       = await res.json()
      this.results    = all.filter(a => !this.selected.has(a.id))
      this._renderDropdown(query)
    } catch (e) {
      if (e.name !== "AbortError") console.error("Author search error:", e)
    } finally {
      this._setLoading(false)
    }
  }

  _renderDropdown(query) {
    const resultItems = this.results.map((author, i) => `
      <li role="option"
          data-combobox-index="${i}"
          data-action="click->author-combobox#selectResult mouseenter->author-combobox#highlight"
          class="px-4 py-2.5 cursor-pointer flex items-center gap-3 text-sm transition-colors duration-75"
          aria-selected="false">
        <span class="text-xs text-gray-400 font-mono w-8 text-right shrink-0">#${author.id}</span>
        <span class="text-gray-800">${this._highlight(author.label, query)}</span>
      </li>
    `).join("")

    const parsed    = this._parseName(query)
    const newLabel  = [parsed.lastName, parsed.firstName].filter(Boolean).join(", ")
    const createItem = `
      <li role="option"
          data-action="click->author-combobox#createAuthor"
          class="px-4 py-2.5 cursor-pointer flex items-center gap-2 text-sm text-indigo-600
                 border-t border-gray-100 hover:bg-indigo-50 transition-colors duration-75">
        <svg class="w-3.5 h-3.5 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4"/>
        </svg>
        <span>Create <strong class="font-semibold">"${newLabel}"</strong></span>
      </li>
    `

    this.listTarget.innerHTML = resultItems + createItem
    this.highlightIndex = -1
    this._open()
  }

  _select(author) {
    if (this.selected.has(author.id)) return

    this.selected.set(author.id, author.label)
    this._addChip(author)
    this.inputTarget.value = ""
    this._close()
    this.inputTarget.focus()
  }

  _addChip(author) {
    const chip = document.createElement("div")
    chip.className = [
      "inline-flex items-center gap-2 pl-4 pr-2.5 py-2",
      "rounded-full text-sm font-medium",
      this.chipClsValue,
      "transition-opacity duration-150"
    ].join(" ")
    chip.dataset.authorId    = author.id
    chip.dataset.authorLabel = author.label
    chip.innerHTML = `
      <span>${author.label}</span>
      <input type="hidden" name="${this.fieldNameValue}" value="${author.id}">
      <button type="button"
              data-author-id="${author.id}"
              data-action="click->author-combobox#removeChip"
              title="Remove"
              class="rounded-full p-1 ${this.btnClsValue} focus:outline-none focus:ring-1 transition-colors">
        <svg class="w-3.5 h-3.5" viewBox="0 0 20 20" fill="currentColor">
          <path d="M6.28 5.22a.75.75 0 00-1.06 1.06L8.94 10l-2.72 2.72a.75.75 0
                   101.06 1.06L10 11.06l2.72 2.72a.75.75 0 101.06-1.06L11.06 10l2.72-2.72a.75.75
                   0 00-1.06-1.06L10 8.94 6.28 5.22z"/>
        </svg>
      </button>
    `
    this.chipsTarget.appendChild(chip)
    requestAnimationFrame(() => chip.classList.add("opacity-100"))
  }

  _open() {
    this.dropdownTarget.classList.remove("hidden")
    this.dropdownTarget.removeAttribute("hidden")
  }

  _close() {
    this.dropdownTarget.classList.add("hidden")
    this.dropdownTarget.setAttribute("hidden", "")
    this.highlightIndex = -1
    this.results = []
  }

  _isClosedDropdown() {
    return this.dropdownTarget.classList.contains("hidden")
  }

  _listItems() {
    return Array.from(this.listTarget.querySelectorAll("[data-combobox-index]"))
  }

  _applyHighlight(items) {
    items.forEach((item, i) => {
      const on = i === this.highlightIndex
      item.classList.toggle("bg-indigo-50", on)
      item.classList.toggle("text-indigo-900", on)
      item.setAttribute("aria-selected", on)
    })
  }

  _setLoading(loading) {
    if (this.hasSpinnerTarget) {
      this.spinnerTarget.classList.toggle("hidden", !loading)
    }
  }

  // Bolds the matched portion of the label
  _highlight(label, query) {
    if (!query) return label
    const escaped = query.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
    return label.replace(new RegExp(`(${escaped})`, "gi"),
      '<strong class="font-semibold text-indigo-700">$1</strong>')
  }

  // Parse "Last, First" or "First Last" or bare "Last"
  _parseName(raw) {
    const q = raw.trim()
    if (!q) return { firstName: "", lastName: "" }

    if (q.includes(",")) {
      const comma   = q.indexOf(",")
      const lastName  = q.slice(0, comma).trim()
      const firstName = q.slice(comma + 1).trim()
      return { firstName, lastName }
    }

    const parts = q.split(/\s+/)
    if (parts.length === 1) return { firstName: "", lastName: parts[0] }

    return {
      firstName: parts.slice(0, -1).join(" "),
      lastName:  parts[parts.length - 1]
    }
  }

  _csrfToken() {
    return document.querySelector("meta[name=csrf-token]")?.content ?? ""
  }

  _handleOutsideClick(event) {
    if (!this.element.contains(event.target)) this._close()
  }
}
