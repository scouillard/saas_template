import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["monthlyButton", "annualButton", "price", "period", "cta"]
  static values = { period: { type: String, default: "monthly" } }

  connect() {
    this.updateDisplay()
  }

  selectMonthly() {
    this.periodValue = "monthly"
    this.updateDisplay()
  }

  selectAnnual() {
    this.periodValue = "annual"
    this.updateDisplay()
  }

  updateDisplay() {
    const isMonthly = this.periodValue === "monthly"

    this.monthlyButtonTarget.classList.toggle("bg-base-100", isMonthly)
    this.monthlyButtonTarget.classList.toggle("text-base-content", isMonthly)
    this.monthlyButtonTarget.classList.toggle("shadow-sm", isMonthly)
    this.monthlyButtonTarget.classList.toggle("text-base-500", !isMonthly)

    this.annualButtonTarget.classList.toggle("bg-base-100", !isMonthly)
    this.annualButtonTarget.classList.toggle("text-base-content", !isMonthly)
    this.annualButtonTarget.classList.toggle("shadow-sm", !isMonthly)
    this.annualButtonTarget.classList.toggle("text-base-500", isMonthly)

    this.priceTargets.forEach(el => {
      const price = isMonthly ? el.dataset.monthlyPrice : el.dataset.annualPrice
      el.textContent = price
    })

    this.periodTargets.forEach(el => {
      el.textContent = isMonthly ? "/month" : "/year"
    })

    this.ctaTargets.forEach(el => {
      el.dataset.billingPeriod = this.periodValue
    })
  }
}
