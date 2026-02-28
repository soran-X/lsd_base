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
      this._setupLinkHandling()
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

  _setupLinkHandling() {
    const toolbar = this.editor.toolbarElement
    if (!toolbar) return

    // Hide Trix's built-in link dialog — we replace it entirely
    const builtIn = toolbar.querySelector(".trix-dialog--link")
    if (builtIn) builtIn.style.display = "none"

    // --- Build custom link popup (styled like Trix's own dialog) ---
    const popup = document.createElement("div")
    Object.assign(popup.style, {
      display:      "none",
      position:     "absolute",
      top:          "0",
      left:         "0",
      right:        "0",
      zIndex:       "20",
      background:   "#fff",
      border:       "1px solid #bbb",
      borderTop:    "2px solid #888",
      borderRadius: "5px",
      boxShadow:    "0 0.3em 1em #ccc",
      padding:      "15px 10px",
      fontSize:     "0.75em",
    })

    const row = document.createElement("div")
    row.style.cssText = "display:flex; align-items:baseline; gap:8px;"

    const urlInput = document.createElement("input")
    urlInput.type        = "text"
    urlInput.placeholder = "Enter a URL…"
    urlInput.style.cssText =
      "flex:1; font-size:inherit; font-weight:normal; padding:0.5em 0.8em; " +
      "border:1px solid #bbb; border-radius:3px; outline:none; " +
      "-webkit-appearance:none; -moz-appearance:none;"

    const applyBtn = document.createElement("input")
    applyBtn.type  = "button"
    applyBtn.value = "Add Link"
    applyBtn.style.cssText =
      "font-size:inherit; padding:0.5em; border:none; border-bottom:none; cursor:pointer;"

    const removeBtn = document.createElement("input")
    removeBtn.type  = "button"
    removeBtn.value = "Remove Link"
    removeBtn.style.cssText = applyBtn.style.cssText

    row.append(urlInput, applyBtn, removeBtn)
    popup.append(row)

    // Append into .trix-dialogs so it uses the same position:relative context
    const dialogsContainer = toolbar.querySelector(".trix-dialogs")
    if (dialogsContainer) {
      dialogsContainer.appendChild(popup)
    } else {
      toolbar.style.position = "relative"
      toolbar.appendChild(popup)
    }

    // --- Track selection continuously so we never lose it ---
    // savedRange is updated on every selection change while the editor has focus.
    // We only keep non-collapsed (text-selected) ranges.
    let savedRange = null
    this.editor.addEventListener("trix-selection-change", () => {
      const ed = this.editor.editor
      if (!ed) return
      const range = ed.getSelectedRange()
      if (range && range[0] !== range[1]) savedRange = range
    })

    const getActiveHref = () => {
      try {
        const sel = window.getSelection()
        const anchor = sel?.anchorNode?.parentElement?.closest("a")
        return anchor?.getAttribute("href") || ""
      } catch (_) { return "" }
    }

    const show = () => {
      urlInput.value = getActiveHref()
      popup.style.display = "block"
      requestAnimationFrame(() => urlInput.focus())
    }

    const hide = () => {
      popup.style.display = "none"
    }

    const apply = () => {
      const url = urlInput.value.trim()
      const ed  = this.editor.editor
      if (!ed || !url) { hide(); return }

      const href = /^(https?:|mailto:|tel:|\/)/i.test(url) ? url : `https://${url}`
      const range = savedRange
      hide()

      this.editor.focus()
      requestAnimationFrame(() => {
        if (range && range[0] !== range[1]) {
          // Restore the saved selection, then replace it with linked HTML.
          // insertHTML is more reliable than activateAttribute for programmatic use
          // because it doesn't depend on the editor having DOM focus at call time.
          ed.setSelectedRange(range)
          const a = document.createElement("a")
          a.href = href
          a.textContent = ed.getDocument().getStringAtRange(range)
          ed.insertHTML(a.outerHTML)
        } else {
          // No text selected — activate attribute so the next typed chars become a link
          if (range) ed.setSelectedRange(range)
          ed.activateAttribute("href", href)
        }
      })
    }

    // --- Intercept the link toolbar button ---
    const linkBtn = toolbar.querySelector('[data-trix-attribute="href"]')
    if (linkBtn) {
      linkBtn.addEventListener("mousedown", (e) => {
        e.preventDefault()   // keep editor focused / selection intact
        e.stopPropagation()  // prevent Trix from opening its own dialog on mousedown
        popup.style.display === "none" ? show() : hide()
      })
      // Also stop the click event so Trix's toolbar click handler doesn't run
      linkBtn.addEventListener("click", (e) => e.stopPropagation())
    }

    // Prevent popup button clicks from stealing editor focus
    applyBtn.addEventListener("mousedown",  (e) => e.preventDefault())
    removeBtn.addEventListener("mousedown", (e) => e.preventDefault())

    applyBtn.addEventListener("click",  (e) => { e.stopPropagation(); apply() })
    removeBtn.addEventListener("click", (e) => {
      e.stopPropagation()
      this.editor.editor?.deactivateAttribute("href")
      hide()
    })

    urlInput.addEventListener("keydown", (e) => {
      if (e.key === "Enter")  { e.preventDefault(); apply() }
      if (e.key === "Escape") { e.preventDefault(); hide() }
    })

    // Close when clicking outside the popup
    this._linkOutsideHandler = (e) => {
      if (popup.style.display !== "none" && !popup.contains(e.target) && e.target !== linkBtn) {
        hide()
      }
    }
    document.addEventListener("click", this._linkOutsideHandler)
  }

  disconnect() {
    if (this._linkOutsideHandler) {
      document.removeEventListener("click", this._linkOutsideHandler)
    }
    this.hidden?.remove()
    this.wrapper?.remove()
  }
}
