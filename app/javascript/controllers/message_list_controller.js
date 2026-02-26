import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { currentUserId: Number }

  connect() {
    this.alignAll()
    // Double rAF: first frame lets Turbo finish DOM insertion,
    // second frame lets the flex layout resolve heights.
    requestAnimationFrame(() => requestAnimationFrame(() => this.scrollToBottom()))

    this.observer = new MutationObserver(mutations => {
      mutations.forEach(m => {
        m.addedNodes.forEach(node => {
          if (node.nodeType !== Node.ELEMENT_NODE) return
          if (node.dataset.userId) this.alignMessage(node)
          node.querySelectorAll("[data-user-id]").forEach(el => this.alignMessage(el))
        })
      })
      this.scrollToBottom()
    })

    this.observer.observe(this.element, { childList: true })
  }

  disconnect() {
    this.observer?.disconnect()
  }

  alignAll() {
    this.element.querySelectorAll("[data-user-id]").forEach(el => this.alignMessage(el))
  }

  alignMessage(el) {
    const isMine = String(el.dataset.userId) === String(this.currentUserIdValue)
    const bubble = el.querySelector("[data-bubble]")
    const senderName = el.querySelector("[data-sender-name]")
    const time = el.querySelector("[data-time]")

    el.classList.toggle("justify-end", isMine)
    el.classList.toggle("justify-start", !isMine)

    if (bubble) {
      if (isMine) {
        bubble.style.backgroundColor = "var(--color-primary)"
        bubble.classList.add("text-white", "rounded-tr-sm")
        bubble.classList.remove("bg-white", "text-gray-900", "rounded-tl-sm", "shadow-sm", "border", "border-gray-100")
      } else {
        bubble.style.backgroundColor = ""
        bubble.classList.add("bg-white", "text-gray-900", "rounded-tl-sm", "shadow-sm", "border", "border-gray-100")
        bubble.classList.remove("text-white", "rounded-tr-sm")
      }
    }

    if (senderName) senderName.classList.toggle("hidden", isMine)

    if (time) {
      time.classList.toggle("text-right", isMine)
      time.classList.toggle("mr-1", isMine)
      time.classList.toggle("ml-1", !isMine)
    }
  }

  scrollToBottom() {
    requestAnimationFrame(() => {
      this.element.scrollTop = this.element.scrollHeight
    })
  }
}
