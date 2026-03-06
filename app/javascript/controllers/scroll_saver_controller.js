import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // When the new page loads, restore the scroll position
    const scrollPosition = sessionStorage.getItem("sidebarScrollPosition")
    if (scrollPosition) {
      this.element.scrollTop = scrollPosition
    }
  }

  save() {
    // Every time the user scrolls, save the position
    sessionStorage.setItem("sidebarScrollPosition", this.element.scrollTop)
  }
}