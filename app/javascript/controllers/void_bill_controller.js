import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { number: String }

  confirm(event) {
    const reason = window.prompt(`Enter a void reason for ${this.numberValue}`)
    if (!reason || !reason.trim()) {
      event.preventDefault()
      return
    }

    if (!window.confirm(`Void bill ${this.numberValue}? It stays listed as voided.`)) {
      event.preventDefault()
      return
    }

    const field = this.element.querySelector("input[name='void_reason']")
    if (field) field.value = reason.trim()
  }
}
