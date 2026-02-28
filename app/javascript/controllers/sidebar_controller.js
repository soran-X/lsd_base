import { Controller } from "@hotwired/stimulus"

/**
 * SidebarController
 *
 * Mobile  (<768px): sidebar is a slide-in overlay driven by the CSS class
 *                   `sidebar-mobile-open` (defined in application.css so it
 *                   doesn't depend on Tailwind JIT picking up JS class names).
 * Desktop (≥768px): sidebar collapses to icon-only (w-16) or expands (w-64).
 *                   State persists in localStorage.
 */
export default class extends Controller {
  static targets = ["sidebar", "main", "chevron", "overlay"]
  static values  = { persist: { type: String, default: "lsd-sidebar-collapsed" } }

  connect() {
    if (this._isMobile()) {
      this._applyMobile(false)
    } else {
      const collapsed = localStorage.getItem(this.persistValue) === "true"
      this._applyDesktop(collapsed)
    }
    this._onResize = () => this._handleResize()
    window.addEventListener("resize", this._onResize)
  }

  disconnect() {
    window.removeEventListener("resize", this._onResize)
  }

  toggle() {
    if (this._isMobile()) {
      const isOpen = this.sidebarTarget.classList.contains("sidebar-mobile-open")
      this._applyMobile(!isOpen)
    } else {
      const collapsed = !this.sidebarTarget.classList.contains("sidebar-collapsed")
      localStorage.setItem(this.persistValue, collapsed)
      this._applyDesktop(collapsed)
    }
  }

  closeOverlay() {
    this._applyMobile(false)
  }

  _isMobile() {
    return window.innerWidth < 768
  }

  _handleResize() {
    if (this._isMobile()) {
      this._applyMobile(false)
    } else {
      const collapsed = localStorage.getItem(this.persistValue) === "true"
      this._applyDesktop(collapsed)
    }
  }

  _applyMobile(open) {
    const sidebar = this.sidebarTarget
    const main    = this.mainTarget

    // Overlay — remove any desktop left margin
    main.classList.remove("ml-64", "ml-16")

    // CSS class drives the transform (see application.css .sidebar-nav)
    sidebar.classList.toggle("sidebar-mobile-open", open)

    // Always show full labels when mobile sidebar is open
    sidebar.classList.remove("sidebar-collapsed")

    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.toggle("hidden", !open)
    }
  }

  _applyDesktop(collapsed) {
    const sidebar = this.sidebarTarget
    const main    = this.mainTarget

    // Clean up any mobile-open state
    sidebar.classList.remove("sidebar-mobile-open")

    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.add("hidden")
    }

    // Width
    sidebar.classList.toggle("w-64", !collapsed)
    sidebar.classList.toggle("w-16",  collapsed)

    // Main content left margin
    main.classList.remove("ml-0")
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
