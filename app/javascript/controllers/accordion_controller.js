import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["trigger", "content", "icon"]

  toggle(event) {
    const trigger = event.currentTarget
    const index = this.triggerTargets.indexOf(trigger)
    const content = this.contentTargets[index]
    const icon = this.iconTargets[index]

    if (content.classList.contains("hidden")) {
      content.classList.remove("hidden")
      icon.classList.add("rotate-180")
    } else {
      content.classList.add("hidden")
      icon.classList.remove("rotate-180")
    }
  }
}
