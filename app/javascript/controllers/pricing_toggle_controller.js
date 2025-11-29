import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["monthlyBtn", "annualBtn", "price"]
  static values = { period: { type: String, default: "monthly" } }

  toggle(event) {
    this.periodValue = event.currentTarget.dataset.period
  }

  periodValueChanged() {
    const isAnnual = this.periodValue === "annual"

    this.monthlyBtnTarget.classList.toggle("bg-primary", !isAnnual)
    this.monthlyBtnTarget.classList.toggle("text-primary-content", !isAnnual)
    this.monthlyBtnTarget.classList.toggle("text-base-content", isAnnual)

    this.annualBtnTarget.classList.toggle("bg-primary", isAnnual)
    this.annualBtnTarget.classList.toggle("text-primary-content", isAnnual)
    this.annualBtnTarget.classList.toggle("text-base-content", !isAnnual)

    this.priceTargets.forEach((el) => {
      const monthly = el.dataset.monthlyPrice
      const annual = el.dataset.annualPrice
      el.textContent = isAnnual ? annual : monthly
    })
  }
}
