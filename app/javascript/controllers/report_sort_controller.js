import { Controller } from "@hotwired/stimulus"

/**
 * ReportSortController
 *
 * Drag-and-drop reordering for grouped book tables on the report show page.
 * Each genre group has its own <tbody data-report-sort-target="tbody">.
 * Books can only be dragged within their own group (cross-group moves blocked).
 * Auto-saves the full global order via PATCH to the reorder endpoint.
 */
export default class extends Controller {
  static targets = ["tbody", "status"]
  static values  = { url: String }

  connect() {
    this._dragging     = null
    this._originTbody  = null
  }

  // ── Drag events on <tr> ──────────────────────────────────────────────────

  dragStart(event) {
    this._dragging    = event.currentTarget
    this._originTbody = event.currentTarget.closest("tbody")
    setTimeout(() => { this._dragging?.classList.add("opacity-40") }, 0)
    event.dataTransfer.effectAllowed = "move"
  }

  dragEnd(event) {
    this._dragging?.classList.remove("opacity-40")
    this._dragging    = null
    this._originTbody = null
    this._refreshNumbers()
    this._save()
  }

  // ── Drag events on <tbody> ───────────────────────────────────────────────

  dragOver(event) {
    event.preventDefault()
    if (!this._dragging) return

    const tbody = event.currentTarget

    // Block cross-group moves — only allow sorting within the origin group
    if (tbody !== this._originTbody) return

    const rows = Array.from(tbody.querySelectorAll("tr[data-book-id]"))
                      .filter(r => r !== this._dragging)

    let insertBefore = null
    for (const row of rows) {
      const mid = row.getBoundingClientRect().top + row.getBoundingClientRect().height / 2
      if (event.clientY < mid) { insertBefore = row; break }
    }

    if (insertBefore) {
      tbody.insertBefore(this._dragging, insertBefore)
    } else {
      tbody.appendChild(this._dragging)
    }
  }

  drop(event) {
    event.preventDefault()
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  _refreshNumbers() {
    // Per-group relative numbers (1, 2, 3… within each group)
    this.tbodyTargets.forEach(tbody => {
      Array.from(tbody.querySelectorAll("tr[data-book-id]")).forEach((row, i) => {
        const cell = row.querySelector("[data-row-number]")
        if (cell) cell.textContent = i + 1
      })
    })
  }

  async _save() {
    // Collect unique book IDs from all tbodies in DOM order (first occurrence wins)
    const seen = new Set()
    const ids  = this.tbodyTargets
      .flatMap(tbody => Array.from(tbody.querySelectorAll("tr[data-book-id]")).map(r => r.dataset.bookId))
      .filter(id => { if (seen.has(id)) return false; seen.add(id); return true })

    const params = new URLSearchParams()
    ids.forEach(id => params.append("book_ids[]", id))

    if (this.hasStatusTarget) {
      this.statusTarget.textContent = "Saving…"
      this.statusTarget.className   = "text-xs text-gray-400"
    }

    const res = await fetch(this.urlValue, {
      method:  "PATCH",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content || ""
      },
      body: params.toString()
    })

    if (this.hasStatusTarget) {
      if (res.ok) {
        this.statusTarget.textContent = "Order saved"
        this.statusTarget.className   = "text-xs text-green-600 font-medium"
        setTimeout(() => { if (this.hasStatusTarget) this.statusTarget.textContent = "" }, 2000)
      } else {
        this.statusTarget.textContent = "Save failed"
        this.statusTarget.className   = "text-xs text-red-500"
      }
    }
  }
}
