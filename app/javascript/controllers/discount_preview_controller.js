import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "percent", "discount", "cgst", "sgst", "grand" ]
  static values = { subtotal: Number, cgstRate: Number, sgstRate: Number }

  connect() {
    this.update()
  }

  update() {
    const percent = this.clampedPercent()
    const subtotal = Number(this.subtotalValue || 0)
    const discount = this.roundMoney(subtotal * percent / 100)
    const taxable = Math.max(subtotal - discount, 0)
    const cgst = this.roundMoney(taxable * Number(this.cgstRateValue || 0))
    const sgst = this.roundMoney(taxable * Number(this.sgstRateValue || 0))
    const grand = this.roundMoney(taxable + cgst + sgst)

    if (this.hasDiscountTarget) this.discountTarget.textContent = `− ₹ ${this.format(discount)}`
    if (this.hasCgstTarget) this.cgstTarget.textContent = `₹ ${this.format(cgst)}`
    if (this.hasSgstTarget) this.sgstTarget.textContent = `₹ ${this.format(sgst)}`
    if (this.hasGrandTarget) this.grandTarget.textContent = `₹ ${this.format(grand)}`
  }

  clampedPercent() {
    if (!this.hasPercentTarget) return 0

    const value = Number(this.percentTarget.value || 0)
    if (Number.isNaN(value)) return 0
    return Math.min(Math.max(value, 0), 100)
  }

  roundMoney(value) {
    return Math.round((value + Number.EPSILON) * 100) / 100
  }

  format(value) {
    return value.toFixed(2)
  }
}
