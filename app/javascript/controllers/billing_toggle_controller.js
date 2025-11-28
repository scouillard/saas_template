import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["monthlyBtn", "annualBtn", "monthlyPrice", "annualPrice"]

  connect() {
    this.showMonthly()
  }

  showMonthly() {
    this.monthlyBtnTarget.classList.add("bg-base-100", "text-base-content", "shadow-sm")
    this.monthlyBtnTarget.classList.remove("text-base-500")
    this.annualBtnTarget.classList.remove("bg-base-100", "text-base-content", "shadow-sm")
    this.annualBtnTarget.classList.add("text-base-500")

    this.monthlyPriceTargets.forEach(el => el.classList.remove("hidden"))
    this.annualPriceTargets.forEach(el => el.classList.add("hidden"))
  }

  showAnnual() {
    this.annualBtnTarget.classList.add("bg-base-100", "text-base-content", "shadow-sm")
    this.annualBtnTarget.classList.remove("text-base-500")
    this.monthlyBtnTarget.classList.remove("bg-base-100", "text-base-content", "shadow-sm")
    this.monthlyBtnTarget.classList.add("text-base-500")

    this.annualPriceTargets.forEach(el => el.classList.remove("hidden"))
    this.monthlyPriceTargets.forEach(el => el.classList.add("hidden"))
  }
}
