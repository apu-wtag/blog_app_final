import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="autosubmit"
export default class extends Controller {
  static targets = ["query"]

  connect() {
    this.handler = this.debounced(() => {
      this.element.requestSubmit()
    }, 300) // Increased to 800ms for more typing time

    this.queryTarget.addEventListener("input", this.handler)
    // Listen for Turbo frame load to restore focus
    document.addEventListener("turbo:frame-load", this.restoreFocus.bind(this))
  }

  disconnect() {
    this.queryTarget.removeEventListener("input", this.handler)
    this.handler.cancel()
    document.removeEventListener("turbo:frame-load", this.restoreFocus.bind(this))
  }

  restoreFocus(event) {
    // Check if the loaded frame is our users_list frame
    if (event.target.id === "users_list" && this.queryTarget) {
      this.queryTarget.focus()
      // Move cursor to the end of the input text
      const valueLength = this.queryTarget.value.length
      this.queryTarget.setSelectionRange(valueLength, valueLength)
    }
  }

  debounced(func, delay) {
    let timeout
    const debouncedFunc = (...args) => {
      if (timeout) clearTimeout(timeout)
      timeout = setTimeout(() => func(...args), delay)
    }
    debouncedFunc.cancel = () => {
      if (timeout) clearTimeout(timeout)
    }
    return debouncedFunc
  }
}