import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["phone", "message", "error"]

  open() {
    const phone = this.normalizePhone(this.phoneTarget.value)
    if (!phone) {
      this.errorTarget.classList.remove("d-none")
      this.phoneTarget.focus()
      return
    }

    this.errorTarget.classList.add("d-none")
    const text = this.messageTarget.textContent.trim()
    const url = `https://wa.me/${phone}?text=${encodeURIComponent(text)}`
    window.open(url, "_blank", "noopener,noreferrer")
  }

  normalizePhone(raw) {
    let digits = String(raw || "").replace(/\D/g, "")
    if (!digits) return ""
    if (digits.length === 10) digits = `91${digits}`
    if (digits.length < 11) return ""
    return digits
  }
}
