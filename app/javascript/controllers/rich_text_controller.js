import { Controller } from "@hotwired/stimulus"

const COLORS = [
  { label: "Remove color", value: null     },
  { label: "Red",          value: "#dc2626" },
  { label: "Orange",       value: "#ea580c" },
  { label: "Amber",        value: "#d97706" },
  { label: "Green",        value: "#16a34a" },
  { label: "Teal",         value: "#0d9488" },
  { label: "Blue",         value: "#2563eb" },
  { label: "Violet",       value: "#7c3aed" },
  { label: "Pink",         value: "#db2777" },
  { label: "Gray",         value: "#6b7280" },
]

export default class extends Controller {
  static values = {
    name:  String,
    value: { type: String, default: "" }
  }

  connect() {
    // Register foreground colour attribute before any editor instance reads config
    if (window.Trix && !Trix.config.textAttributes.foregroundColor) {
      Trix.config.textAttributes.foregroundColor = {
        styleProperty: "color",
        inheritable:   1
      }
    }

    const uid = `trix_${Math.random().toString(36).slice(2)}`

    this.hidden       = document.createElement("input")
    this.hidden.type  = "hidden"
    this.hidden.id    = uid
    this.hidden.name  = this.nameValue
    this.hidden.value = this.valueValue

    this.wrapper = document.createElement("div")
    this.wrapper.className = [
      "rt-wrapper rounded-lg border border-gray-300",
      "focus-within:ring-2 focus-within:ring-indigo-500 focus-within:border-transparent",
      "transition-shadow duration-150"
    ].join(" ")

    this.editor = document.createElement("trix-editor")
    this.editor.setAttribute("input", uid)
    this.editor.style.minHeight  = "10rem"
    this.editor.style.display    = "block"
    this.editor.style.padding    = "0.5rem 0.75rem"
    this.editor.style.fontSize   = "0.875rem"
    this.editor.style.lineHeight = "1.6"

    this.wrapper.appendChild(this.editor)
    this.element.appendChild(this.hidden)
    this.element.appendChild(this.wrapper)

    this.editor.addEventListener("trix-change", () => {
      this.hidden.value = this.editor.value
    })

    this.editor.addEventListener("trix-initialize", () => {
      this._addColorRow()
    })
  }

  _addColorRow() {
    const toolbar = this.editor.toolbarElement
    if (!toolbar || toolbar.querySelector(".trix-color-row")) return

    const row = document.createElement("div")
    row.className =
      "trix-color-row flex items-center gap-1.5 px-3 py-2 bg-gray-50 border-t border-gray-200"

    const lbl = document.createElement("span")
    lbl.className   = "text-xs text-gray-400 shrink-0 mr-0.5"
    lbl.textContent = "Color:"
    row.appendChild(lbl)

    COLORS.forEach(({ label, value }) => {
      const btn = document.createElement("button")
      btn.type      = "button"
      btn.title     = label
      btn.className =
        "w-5 h-5 rounded-full border border-gray-300 flex-shrink-0 cursor-pointer " +
        "hover:scale-110 transition-transform focus:outline-none focus:ring-2 focus:ring-offset-1 focus:ring-indigo-400"

      if (value === null) {
        // "Remove color" — white circle with a diagonal slash
        btn.style.background = "#f9fafb"
        btn.style.position   = "relative"
        btn.style.overflow   = "hidden"
        btn.innerHTML =
          `<svg viewBox="0 0 20 20" fill="none" class="w-full h-full">
             <line x1="3" y1="3" x2="17" y2="17" stroke="#9ca3af" stroke-width="2.5"/>
           </svg>`
      } else {
        btn.style.backgroundColor = value
        btn.style.borderColor     = value
      }

      btn.addEventListener("mousedown", (e) => {
        e.preventDefault()           // keep the editor selection alive
        const ed = this.editor.editor
        if (!ed) return
        value === null
          ? ed.deactivateAttribute("foregroundColor")
          : ed.activateAttribute("foregroundColor", value)
      })

      row.appendChild(btn)
    })

    toolbar.appendChild(row)
  }

  disconnect() {
    this.hidden?.remove()
    this.wrapper?.remove()
  }
}
