import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "burger", "backdrop"]

  toggle() {
    this.menuTarget.classList.toggle('active')
    this.burgerTarget.classList.toggle('active')
    this.backdropTarget.classList.toggle('active')
  }

  close() {
    this.menuTarget.classList.remove('active')
    this.burgerTarget.classList.remove('active')
    this.backdropTarget.classList.remove('active')
  }
}
