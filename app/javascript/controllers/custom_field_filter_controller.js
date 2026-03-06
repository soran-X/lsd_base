import { Controller } from "@hotwired/stimulus"

/**
 * CustomFieldFilterController
 *
 * Manages dynamic custom-field filter rows in the advanced-search form.
 *
 * Values:
 *   fields            – Array of field definitions [{id, name, field_type, choices}]
 *   saved             – Object map of { "field_id": value } for pre-populating saved searches.
 *                       For contact/company types the value is {id, label}; for others it's a scalar.
 *   contactSearchUrl  – URL for the contact autocomplete endpoint
 *   companySearchUrl  – URL for the company autocomplete endpoint
 *
 * Targets:
 *   rows – container where filter rows are appended
 */
export default class extends Controller {
  static targets = ["rows"]
  static values  = {
    fields:           Array,
    saved:            Object,
    contactSearchUrl: String,
    companySearchUrl: String
  }

  connect() {
    Object.entries(this.savedValue || {}).forEach(([fieldId, value]) => {
      this.rowsTarget.appendChild(this._buildRow(parseInt(fieldId, 10), value))
    })
  }

  addRow() {
    this.rowsTarget.appendChild(this._buildRow(null, null))
  }

  removeRow(event) {
    event.currentTarget.closest("[data-filter-row]").remove()
  }

  fieldChanged(event) {
    const select = event.currentTarget
    const row    = select.closest("[data-filter-row]")
    const fieldId = parseInt(select.value, 10)
    const container = row.querySelector("[data-value-container]")
    container.innerHTML = ""
    if (!fieldId) return
    const field = this.fieldsValue.find(f => f.id === fieldId)
    if (field) container.innerHTML = this._buildValueInput(field, null)
  }

  // ── Private ─────────────────────────────────────────────────────────────────

  _buildRow(fieldId, savedValue) {
    const row = document.createElement("div")
    row.dataset.filterRow = ""
    row.className = "flex items-start gap-2"

    // Field selector
    const selectWrap = document.createElement("div")
    selectWrap.className = "w-52 shrink-0"

    const select = document.createElement("select")
    select.dataset.action = "change->custom-field-filter#fieldChanged"
    select.className = [
      "w-full rounded-lg border border-gray-300 px-3 py-2 text-sm",
      "focus:outline-none focus:ring-2 focus:ring-indigo-500"
    ].join(" ")

    const blank = new Option("— Select field —", "")
    select.appendChild(blank)

    this.fieldsValue.forEach(field => {
      const opt = new Option(field.name, field.id)
      if (fieldId && field.id === fieldId) opt.selected = true
      select.appendChild(opt)
    })
    selectWrap.appendChild(select)

    // Value container
    const valueContainer = document.createElement("div")
    valueContainer.dataset.valueContainer = ""
    valueContainer.className = "flex-1"

    // Remove button
    const removeBtn = document.createElement("button")
    removeBtn.type = "button"
    removeBtn.dataset.action = "click->custom-field-filter#removeRow"
    removeBtn.className = "mt-2 p-1 text-gray-400 hover:text-red-500 transition-colors shrink-0"
    removeBtn.title = "Remove filter"
    removeBtn.innerHTML = `<svg class="w-4 h-4" viewBox="0 0 20 20" fill="currentColor">
      <path d="M6.28 5.22a.75.75 0 00-1.06 1.06L8.94 10l-2.72 2.72a.75.75 0 101.06 1.06L10 11.06l2.72 2.72a.75.75 0 101.06-1.06L11.06 10l2.72-2.72a.75.75 0 00-1.06-1.06L10 8.94 6.28 5.22z"/>
    </svg>`

    row.appendChild(selectWrap)
    row.appendChild(valueContainer)
    row.appendChild(removeBtn)

    if (fieldId) {
      const field = this.fieldsValue.find(f => f.id === fieldId)
      if (field) valueContainer.innerHTML = this._buildValueInput(field, savedValue)
    }

    return row
  }

  _buildValueInput(field, savedValue) {
    const id = field.id
    const sv  = savedValue
    const inputClass = [
      "w-full rounded-lg border border-gray-300 px-3 py-2 text-sm",
      "focus:outline-none focus:ring-2 focus:ring-indigo-500"
    ].join(" ")

    switch (field.field_type) {
      case "text":
      case "rich_text":
        return `<input type="text" name="q[cf][${id}]" value="${this._esc(sv || "")}" placeholder="Contains…" class="${inputClass}">`

      case "checkbox": {
        const val = sv || ""
        return `<select name="q[cf][${id}]" class="${inputClass}">
          <option value="">Any</option>
          <option value="true"${val === "true" ? " selected" : ""}>Yes</option>
          <option value="false"${val === "false" ? " selected" : ""}>No</option>
        </select>`
      }

      case "combobox":
      case "multi_combobox": {
        const val  = sv || ""
        const opts = field.choices.map(c =>
          `<option value="${this._esc(c)}"${val === c ? " selected" : ""}>${this._esc(c)}</option>`
        ).join("")
        return `<select name="q[cf][${id}]" class="${inputClass}">
          <option value="">— any —</option>
          ${opts}
        </select>`
      }

      case "contact_select":
      case "multi_contact_select": {
        const contactId    = sv && typeof sv === "object" ? (sv.id || "") : ""
        const contactLabel = sv && typeof sv === "object" ? (sv.label || "") : ""
        const url = this.contactSearchUrlValue
        return `<div data-controller="contact-combobox" data-contact-combobox-url-value="${url}" class="relative">
          <input type="text"
                 data-contact-combobox-target="input"
                 data-action="input->contact-combobox#search keydown->contact-combobox#onKeydown"
                 value="${this._esc(contactLabel)}"
                 placeholder="Search contacts…"
                 autocomplete="off"
                 class="${inputClass}">
          <input type="hidden"
                 data-contact-combobox-target="hiddenField"
                 name="q[cf][${id}]"
                 value="${this._esc(contactId)}">
          <div data-contact-combobox-target="dropdown"
               class="hidden absolute left-0 right-0 mt-1 bg-white border border-gray-200 rounded-xl shadow-xl z-50 overflow-hidden"></div>
        </div>`
      }

      case "company_select":
      case "multi_company_select": {
        const companyId    = sv && typeof sv === "object" ? (sv.id || "") : ""
        const companyLabel = sv && typeof sv === "object" ? (sv.label || "") : ""
        const url = this.companySearchUrlValue
        return `<div data-controller="company-combobox" data-company-combobox-url-value="${url}" class="relative">
          <input type="text"
                 data-company-combobox-target="input"
                 data-action="input->company-combobox#search keydown->company-combobox#onKeydown"
                 value="${this._esc(companyLabel)}"
                 placeholder="Search companies…"
                 autocomplete="off"
                 class="${inputClass}">
          <input type="hidden"
                 data-company-combobox-target="hiddenField"
                 name="q[cf][${id}]"
                 value="${this._esc(companyId)}">
          <div data-company-combobox-target="dropdown"
               class="hidden absolute left-0 right-0 mt-1 bg-white border border-gray-200 rounded-xl shadow-xl z-50 overflow-hidden"></div>
        </div>`
      }

      default:
        return `<input type="text" name="q[cf][${id}]" value="${this._esc(sv || "")}" placeholder="Value…" class="${inputClass}">`
    }
  }

  _esc(str) {
    return String(str || "")
      .replace(/&/g, "&amp;")
      .replace(/"/g, "&quot;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
  }
}
