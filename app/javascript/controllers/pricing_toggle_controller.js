import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["monthlyBtn", "annualBtn", "monthlyPrice", "annualPrice"]

  showMonthly() {
    this.setActive("monthly")
  }

  showAnnual() {
    this.setActive("annual")
  }

  setActive(period) {
    const isMonthly = period === "monthly"

    // Update all controllers on the page (toggle and cards share targets)
    document.querySelectorAll('[data-pricing-toggle-target="monthlyBtn"]').forEach(btn => {
      btn.classList.toggle("bg-base-100", isMonthly)
      btn.classList.toggle("text-base-content", isMonthly)
      btn.classList.toggle("shadow-sm", isMonthly)
      btn.classList.toggle("text-base-500", !isMonthly)
    })

    document.querySelectorAll('[data-pricing-toggle-target="annualBtn"]').forEach(btn => {
      btn.classList.toggle("bg-base-100", !isMonthly)
      btn.classList.toggle("text-base-content", !isMonthly)
      btn.classList.toggle("shadow-sm", !isMonthly)
      btn.classList.toggle("text-base-500", isMonthly)
    })

    document.querySelectorAll('[data-pricing-toggle-target="monthlyPrice"]').forEach(el => {
      el.classList.toggle("hidden", !isMonthly)
      el.classList.toggle("block", isMonthly)
    })

    document.querySelectorAll('[data-pricing-toggle-target="annualPrice"]').forEach(el => {
      el.classList.toggle("hidden", isMonthly)
      el.classList.toggle("block", !isMonthly)
    })
  }
}
