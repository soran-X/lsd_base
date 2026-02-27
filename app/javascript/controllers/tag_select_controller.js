import { Controller } from "@hotwired/stimulus"

/**
 * TagSelectController
 *
 * Generic tag-style multi-select for any fixed list (genres, client types, etc.)
 * Selected items appear as removable pills; a <select> dropdown adds more.
 *
 * Values:
 *   selected  – initial array of {id, name} objects (JSON from server)
 *   fieldName – hidden input name, e.g. "book[genre_ids][]"
 *   color     – pill colour theme: "violet" | "emerald" | "blue" | "indigo"
 *
 * Targets:
 *   tags   – pill container
 *   inputs – hidden input container
 *   select – <select> dropdown for adding items
 */

// Full class strings so Tailwind v4 scanner includes them
const PILL_CLASSES = {
  violet:  "bg-violet-50  text-violet-700  border-violet-200",
  emerald: "bg-emerald-50 text-emerald-800 border-emerald-200",
  blue:    "bg-blue-50    text-blue-700    border-blue-200",
  indigo:  "bg-indigo-50  text-indigo-700  border-indigo-200",
  amber:   "bg-amber-50   text-amber-800   border-amber-200",
  rose:    "bg-rose-50    text-rose-800    border-rose-200",
}
const CLOSE_CLASSES = {
  violet:  "hover:text-violet-900",
  emerald: "hover:text-emerald-900",
  blue:    "hover:text-blue-900",
  indigo:  "hover:text-indigo-900",
  amber:   "hover:text-amber-900",
  rose:    "hover:text-rose-900",
}

export default class extends Controller {
  static targets = ["tags", "inputs", "select"]
  static values  = {
    selected:  { type: Array,  default: [] },
    fieldName: { type: String, default: "item[tag_ids][]" },
    color:     { type: String, default: "violet" },
  }

  connect() {
    this.render()
  }

  add(event) {
    const opt = event.target.selectedOptions[0]
    if (!opt?.value) return

    const id   = parseInt(opt.value)
    const name = opt.text.replace(/^↳\s*/, "")   // strip prefix from subgenre entries

    if (!this.selectedValue.some(t => t.id === id)) {
      this.selectedValue = [...this.selectedValue, { id, name }]
      this.render()
    }
    event.target.value = ""
  }

  remove({ params }) {
    this.selectedValue = this.selectedValue.filter(t => t.id !== params.id)
    this.render()
  }

  render() {
    this._renderTags()
    this._renderInputs()
    this._syncOptions()
  }

  _renderTags() {
    const color = this.colorValue
    const pill  = PILL_CLASSES[color]  ?? PILL_CLASSES.violet
    const close = CLOSE_CLASSES[color] ?? CLOSE_CLASSES.violet

    if (this.selectedValue.length === 0) {
      this.tagsTarget.innerHTML =
        '<span class="text-sm text-gray-400 italic">None selected</span>'
      return
    }

    this.tagsTarget.innerHTML = this.selectedValue.map(({ id, name }) => `
      <span class="inline-flex items-center gap-1 px-3 py-1 rounded-full text-sm border ${pill}">
        ${this._esc(name)}
        <button type="button"
                data-action="click->tag-select#remove"
                data-tag-select-id-param="${id}"
                class="${close} transition-colors ml-0.5 flex-shrink-0"
                title="Remove">
          <svg class="w-3 h-3" viewBox="0 0 20 20" fill="currentColor">
            <path d="M6.28 5.22a.75.75 0 00-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 101.06 1.06L10 11.06l3.72 3.72a.75.75 0 101.06-1.06L11.06 10l3.72-3.72a.75.75 0 00-1.06-1.06L10 8.94 6.28 5.22z"/>
          </svg>
        </button>
      </span>
    `).join("")
  }

  _renderInputs() {
    const c = this.inputsTarget
    c.innerHTML = `<input type="hidden" name="${this.fieldNameValue}" value="">`
    this.selectedValue.forEach(({ id }) => {
      const inp  = document.createElement("input")
      inp.type   = "hidden"
      inp.name   = this.fieldNameValue
      inp.value  = id
      c.appendChild(inp)
    })
  }

  _syncOptions() {
    const ids = new Set(this.selectedValue.map(t => t.id))
    Array.from(this.selectTarget.options).forEach(opt => {
      if (!opt.value) return
      opt.hidden = ids.has(parseInt(opt.value))
    })
  }

  _esc(str) {
    return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
  }
}
