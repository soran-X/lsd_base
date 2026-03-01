import { Controller } from "@hotwired/stimulus"

/**
 * FilmGenreChipsController
 *
 * Multi-select search combobox for film genres — supports creating new genres
 * on the fly if no match exists.
 *
 * Values:
 *   search-url  – GET endpoint returning [{id, label}]
 *   create-url  – POST endpoint to create a new genre (returns {id, label})
 *   field-name  – Hidden input name, e.g. "book[film_genre_ids][]"
 */
export default class extends Controller {
  static targets = ["input", "dropdown", "list", "chips"]
  static values  = {
    searchUrl: String,
    createUrl: String,
    fieldName: String
  }

  connect() {
    this.selected       = new Map()
    this.results        = []
    this.highlightIndex = -1
    this.debounceTimer  = null
    this.abort          = null
    this._currentQuery  = ""

    this._outsideClick = this._handleOutsideClick.bind(this)
    document.addEventListener("click", this._outsideClick)

    this.chipsTarget.querySelectorAll("[data-genre-id]").forEach(chip => {
      this.selected.set(parseInt(chip.dataset.genreId), chip.dataset.genreLabel)
    })
  }

  disconnect() {
    document.removeEventListener("click", this._outsideClick)
    if (this.abort) this.abort.abort()
    clearTimeout(this.debounceTimer)
  }

  onInput() {
    const q = this.inputTarget.value.trim()
    this._currentQuery = q
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
        if (this.highlightIndex >= 0) {
          const item = items[this.highlightIndex]
          if (item?.dataset.createItem) {
            this._createGenre(this._currentQuery)
          } else if (this.results[this.highlightIndex]) {
            this._select(this.results[this.highlightIndex])
          }
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

  createFromClick(event) {
    const q = event.currentTarget.dataset.query
    if (q) this._createGenre(q)
  }

  removeChip(event) {
    const id   = parseInt(event.currentTarget.dataset.genreId)
    const chip = this.chipsTarget.querySelector(`[data-genre-id="${id}"]`)
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
      this.results = all.filter(g => !this.selected.has(g.id))
      this._renderDropdown(query)
    } catch (e) {
      if (e.name !== "AbortError") console.error("Film genre chips search error:", e)
    }
  }

  _renderDropdown(query) {
    const exactMatch = this.results.some(
      g => g.label.toLowerCase() === query.toLowerCase()
    )

    const rows = this.results.map((g, i) => `
      <li role="option"
          data-combobox-index="${i}"
          data-action="click->film-genre-chips#selectResult mouseenter->film-genre-chips#highlight"
          class="px-4 py-2.5 cursor-pointer flex items-center gap-3 text-sm transition-colors duration-75"
          aria-selected="false">
        <span>${this._highlight(g.label, query)}</span>
      </li>
    `).join("")

    const createRow = !exactMatch && query.length > 0 ? `
      <li role="option"
          data-create-item="true"
          data-combobox-index="${this.results.length}"
          data-query="${this._escapeAttr(query)}"
          data-action="click->film-genre-chips#createFromClick mouseenter->film-genre-chips#highlight"
          class="px-4 py-2.5 cursor-pointer flex items-center gap-2 text-sm text-indigo-600 border-t border-gray-100 transition-colors duration-75"
          aria-selected="false">
        <svg class="w-4 h-4 shrink-0" viewBox="0 0 20 20" fill="currentColor">
          <path d="M10.75 4.75a.75.75 0 00-1.5 0v4.5h-4.5a.75.75 0 000 1.5h4.5v4.5a.75.75 0 001.5 0v-4.5h4.5a.75.75 0 000-1.5h-4.5v-4.5z"/>
        </svg>
        <span>Create "<strong class="font-semibold">${this._escapeHtml(query)}</strong>"</span>
      </li>
    ` : ""

    if (!rows && !createRow) {
      this.listTarget.innerHTML =
        '<li class="px-4 py-3 text-sm text-gray-400 italic">No genres found.</li>'
    } else {
      this.listTarget.innerHTML = rows + createRow
    }
    this.highlightIndex = -1
    this._open()
  }

  async _createGenre(name) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    try {
      const res = await fetch(this.createUrlValue, {
        method:  "POST",
        headers: {
          "Content-Type":  "application/json",
          "Accept":        "application/json",
          "X-CSRF-Token":  csrfToken || ""
        },
        body: JSON.stringify({ film_genre: { name } })
      })
      if (!res.ok) return
      const genre = await res.json()
      this._select(genre)
    } catch (e) {
      console.error("Film genre create error:", e)
    }
  }

  _select(genre) {
    if (this.selected.has(genre.id)) return
    this.selected.set(genre.id, genre.label)
    this._addChip(genre)
    this.inputTarget.value = ""
    this._currentQuery = ""
    this._close()
    this.inputTarget.focus()
  }

  _addChip(genre) {
    const chip = document.createElement("div")
    chip.className =
      "inline-flex items-center gap-2 pl-3 pr-2 py-1.5 rounded-full text-sm font-medium " +
      "bg-purple-50 text-purple-800 border border-purple-200"
    chip.dataset.genreId    = genre.id
    chip.dataset.genreLabel = genre.label
    chip.innerHTML = `
      <span>${this._escapeHtml(genre.label)}</span>
      <input type="hidden" name="${this.fieldNameValue}" value="${genre.id}">
      <button type="button"
              data-genre-id="${genre.id}"
              data-action="click->film-genre-chips#removeChip"
              title="Remove"
              class="rounded-full p-0.5 hover:bg-purple-200 text-purple-400 hover:text-purple-700 transition-colors">
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
    if (!query) return this._escapeHtml(label)
    const esc = query.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
    return this._escapeHtml(label).replace(
      new RegExp(`(${esc})`, "gi"),
      '<strong class="font-semibold text-indigo-700">$1</strong>'
    )
  }

  _escapeHtml(str) {
    return String(str)
      .replace(/&/g, "&amp;").replace(/</g, "&lt;")
      .replace(/>/g, "&gt;").replace(/"/g, "&quot;")
  }

  _escapeAttr(str) {
    return String(str).replace(/"/g, "&quot;").replace(/'/g, "&#39;")
  }

  _handleOutsideClick(e) {
    if (!this.element.contains(e.target)) this._close()
  }
}
