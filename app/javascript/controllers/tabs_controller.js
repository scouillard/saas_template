import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel", "intervalInput"]
  static values = {
    active: String,
    activeClass: { type: String, default: "bg-base-100 text-base-content shadow-sm" },
    inactiveClass: { type: String, default: "text-base-500" }
  }

  select(event) {
    this.activeValue = event.currentTarget.dataset.tabsId
  }

  activeValueChanged() {
    this.tabTargets.forEach(tab => {
      const isActive = tab.dataset.tabsId === this.activeValue
      this.activeClassValue.split(" ").forEach(c => tab.classList.toggle(c, isActive))
      this.inactiveClassValue.split(" ").forEach(c => tab.classList.toggle(c, !isActive))
    })

    this.panelTargets.forEach(panel => {
      panel.classList.toggle("hidden", panel.dataset.tabsId !== this.activeValue)
    })

    this.updateIntervalInputs()
  }

  updateIntervalInputs() {
    this.intervalInputTargets.forEach(input => {
      input.value = this.activeValue
    })
  }
}
