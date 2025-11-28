import { Controller } from "@hotwired/stimulus"
import { post } from "@rails/request.js"

export default class extends Controller {
  static targets = ["indicator"]

  markSeen() {
    if (this.hasIndicatorTarget) {
      this.indicatorTarget.remove()
      post("/notifications/mark_all_seen")
    }
  }
}
