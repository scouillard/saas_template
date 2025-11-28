import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["monthlyButton", "annualButton", "monthlyPrice", "annualPrice"]
  static values = { period: { type: String, default: "monthly" } }

  toggle(event) {
    const period = event.currentTarget.dataset.period
    this.periodValue = period
  }

  periodValueChanged() {
    this.updateButtons()
    this.updatePrices()
  }

  updateButtons() {
    const activeClasses = ["bg-base-100", "text-base-content", "shadow-sm"]
    const inactiveClasses = ["text-base-500", "hover:text-base-content"]

    if (this.periodValue === "monthly") {
      this.monthlyButtonTarget.classList.add(...activeClasses)
      this.monthlyButtonTarget.classList.remove(...inactiveClasses)
      this.annualButtonTarget.classList.remove(...activeClasses)
      this.annualButtonTarget.classList.add(...inactiveClasses)
    } else {
      this.annualButtonTarget.classList.add(...activeClasses)
      this.annualButtonTarget.classList.remove(...inactiveClasses)
      this.monthlyButtonTarget.classList.remove(...activeClasses)
      this.monthlyButtonTarget.classList.add(...inactiveClasses)
    }
  }

  updatePrices() {
    this.monthlyPriceTargets.forEach(el => {
      el.classList.toggle("hidden", this.periodValue !== "monthly")
    })
    this.annualPriceTargets.forEach(el => {
      el.classList.toggle("hidden", this.periodValue !== "annual")
    })
  }
}
