import { Controller } from "@hotwired/stimulus"

/**
 * GlobalSearchController
 *
 * Sticky top-bar search with ⌘K/Ctrl+K shortcut.
 * Results link to book show pages.
 * "Create Report" footer navigates to /reports/new?book_ids[]=...
 *
 * Values:
 *   search-url   – e.g. /search.json
 *   reports-url  – e.g. /reports/new
 */
export default class extends Controller {
  static targets = ["input", "dropdown", "list", "reportBtn"]
  static values  = {
    searchUrl:  String,
    reportsUrl: String
  }

  connect() {
    this.results        = []
    this.highlightIndex = -1
    this.debounceTimer  = null
    this.abort          = null

    this._keydown       = this._handleGlobalKeydown.bind(this)
    this._outsideClick  = this._handleOutsideClick.bind(this)
    document.addEventListener("keydown", this._keydown)
    document.addEventListener("click",   this._outsideClick)
  }

  disconnect() {
    document.removeEventListener("keydown", this._keydown)
    document.removeEventListener("click",   this._outsideClick)
    if (this.abort) this.abort.abort()
    clearTimeout(this.debounceTimer)
  }

  focus() {
    this.inputTarget.focus()
    this.inputTarget.select()
  }

  onInput() {
    const q = this.inputTarget.value.trim()
    clearTimeout(this.debounceTimer)
    if (q.length < 2) { this._close(); return }
    this.debounceTimer = setTimeout(() => this._search(q), 250)
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
          window.location = this.results[this.highlightIndex].url
        }
        break
      case "Escape":
        this._close()
        this.inputTarget.blur()
        break
    }
  }

  highlight(event) {
    const idx = parseInt(event.currentTarget.dataset.resultIndex)
    if (!isNaN(idx)) {
      this.highlightIndex = idx
      this._applyHighlight(this._listItems())
    }
  }

  openResult(event) {
    const idx = parseInt(event.currentTarget.dataset.resultIndex)
    if (!isNaN(idx) && this.results[idx]) {
      window.location = this.results[idx].url
    }
  }

  createReport() {
    if (!this.results.length) return
    const ids = this.results.map(r => `book_ids[]=${r.id}`).join("&")
    window.location = `${this.reportsUrlValue}?${ids}`
  }

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
      this.results = await res.json()
      this._renderDropdown(query)
    } catch (e) {
      if (e.name !== "AbortError") console.error("Global search error:", e)
    }
  }

  _renderDropdown(query) {
    if (!this.results.length) {
      this.listTarget.innerHTML =
        '<li class="px-4 py-4 text-sm text-gray-400 italic text-center">No results found.</li>'
      if (this.hasReportBtnTarget) this.reportBtnTarget.classList.add("hidden")
      this._open()
      return
    }

    this.listTarget.innerHTML = this.results.map((r, i) => `
      <li role="option"
          data-result-index="${i}"
          data-action="click->global-search#openResult mouseenter->global-search#highlight"
          class="px-4 py-2.5 cursor-pointer transition-colors duration-75"
          aria-selected="false">
        <p class="text-sm font-medium text-gray-900 truncate">${this._esc(r.title)}</p>
        ${r.authors ? `<p class="text-xs text-gray-500 truncate">${this._esc(r.authors)}</p>` : ""}
      </li>
    `).join("")

    if (this.hasReportBtnTarget) this.reportBtnTarget.classList.remove("hidden")
    this.highlightIndex = -1
    this._open()
  }

  _open()  {
    this.dropdownTarget.classList.remove("hidden")
    this.dropdownTarget.removeAttribute("hidden")
  }
  _close() {
    this.dropdownTarget.classList.add("hidden")
    this.dropdownTarget.setAttribute("hidden", "")
    this.highlightIndex = -1
  }
  _isClosed() { return this.dropdownTarget.classList.contains("hidden") }
  _listItems() { return Array.from(this.listTarget.querySelectorAll("[data-result-index]")) }

  _applyHighlight(items) {
    items.forEach((item, i) => {
      const on = i === this.highlightIndex
      item.classList.toggle("bg-indigo-50", on)
      item.setAttribute("aria-selected", on)
    })
  }

  _esc(str) {
    return String(str)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
  }

  _handleGlobalKeydown(e) {
    if ((e.metaKey || e.ctrlKey) && e.key === "k") {
      e.preventDefault()
      this.focus()
      this._open()
    }
  }

  _handleOutsideClick(e) {
    if (!this.element.contains(e.target)) this._close()
  }
}
