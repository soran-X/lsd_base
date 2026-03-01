import { Controller } from "@hotwired/stimulus"

/**
 * Copies Book Info rich-text fields into Film Info:
 *   book[pub_info]  → film_tracking[comments]
 *   book[synopsis]  → film_tracking[film_synopsis]
 *   book[material]  → film_tracking[material]
 *
 * Shows a themed <dialog> confirmation modal before overwriting.
 */
export default class extends Controller {
  static targets = ["dialog", "commentsContainer", "synopsisContainer", "materialContainer"]

  open(event) {
    event.preventDefault()
    this.dialogTarget.showModal()
  }

  confirm() {
    this.dialogTarget.close()

    const pubInfo  = this._readSource("book[pub_info]")
    const synopsis = this._readSource("book[synopsis]")
    const material = this._readSource("book[material]")

    if (pubInfo  !== null && this.hasCommentsContainerTarget)  this._writeEditor(this.commentsContainerTarget,  pubInfo)
    if (synopsis !== null && this.hasSynopsisContainerTarget)  this._writeEditor(this.synopsisContainerTarget,  synopsis)
    if (material !== null && this.hasMaterialContainerTarget)  this._writeEditor(this.materialContainerTarget,  material)
  }

  cancel() {
    this.dialogTarget.close()
  }

  _readSource(fieldName) {
    const input = document.querySelector(`input[name="${fieldName}"]`)
    return input ? input.value : null
  }

  _writeEditor(container, html) {
    const trixEl = container.querySelector("trix-editor")
    if (!trixEl) return
    if (trixEl.editor) {
      trixEl.editor.loadHTML(html)
    } else {
      trixEl.addEventListener("trix-initialize", () => trixEl.editor.loadHTML(html), { once: true })
    }
  }
}
