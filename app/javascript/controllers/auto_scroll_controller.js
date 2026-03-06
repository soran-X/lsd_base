import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("Controller is ALIVE!") // Just to prove it's working
    
    const savedPosition = sessionStorage.getItem("sidebarScroll")
    if (savedPosition) {
      // requestAnimationFrame ensures the browser has finished painting the HTML 
      // before we try to force the scrollbar down.
      requestAnimationFrame(() => {
        this.element.scrollTop = savedPosition
      })
    }
  }

  disconnect() {
    // Save the exact scroll position right before Turbo swaps the page
    sessionStorage.setItem("sidebarScroll", this.element.scrollTop)
  }
}