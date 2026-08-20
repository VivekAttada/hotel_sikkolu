import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.scrollIntoView({ behavior: "smooth", block: "nearest" })

    this.timeout = window.setTimeout(() => {
      this.element.querySelectorAll(".alert").forEach((alert) => {
        const instance = window.bootstrap?.Alert?.getOrCreateInstance(alert)
        if (instance) {
          instance.close()
        } else {
          alert.remove()
        }
      })
    }, 5000)
  }

  disconnect() {
    if (this.timeout) {
      window.clearTimeout(this.timeout)
    }
  }
}
