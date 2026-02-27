import { Controller } from "@hotwired/stimulus"

/**
 * SidebarController
 *
 * Toggles the sidebar between full (w-64, labels visible) and
 * icon-only (w-16, labels hidden). State persists in localStorage.
 *
 * Targets:
 *   sidebar  – the <aside> element
 *   main     – the main content wrapper (gets matching margin)
 *   chevron  – the toggle icon (rotates 180° when collapsed)
 *
 * CSS classes on <aside> drive child visibility:
 *   .sidebar-label   – text labels next to icons (hidden when collapsed)
 *   .sidebar-section – section headings like "Content" / "Admin"
 *   .sidebar-footer  – footer text (name, role, sign-out label)
 */
export default class extends Controller {
  static targets = ["sidebar", "main", "chevron"]
  static values  = { persist: { type: String, default: "lsd-sidebar-collapsed" } }

  connect() {
    const collapsed = localStorage.getItem(this.persistValue) === "true"
    this._apply(collapsed, false)  // no animation on initial load
  }

  toggle() {
    const collapsed = !this.sidebarTarget.classList.contains("sidebar-collapsed")
    localStorage.setItem(this.persistValue, collapsed)
    this._apply(collapsed, true)
  }

  _apply(collapsed, animate) {
    const sidebar = this.sidebarTarget
    const main    = this.mainTarget

    // Width
    sidebar.classList.toggle("w-64", !collapsed)
    sidebar.classList.toggle("w-16",  collapsed)

    // Main content left margin
    main.classList.toggle("ml-64", !collapsed)
    main.classList.toggle("ml-16",  collapsed)

    // CSS hook — child elements use .sidebar-collapsed .sidebar-label etc.
    sidebar.classList.toggle("sidebar-collapsed", collapsed)

    // Chevron rotation
    if (this.hasChevronTarget) {
      this.chevronTarget.classList.toggle("rotate-180", collapsed)
    }
  }
}
