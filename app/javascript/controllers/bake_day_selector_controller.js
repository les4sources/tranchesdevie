import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="bake-day-selector"
export default class extends Controller {
  static targets = ["button"]

  connect() {
    console.log("Bake day selector connected")
  }

  select(event) {
    // Add loading state
    this.buttonTargets.forEach(btn => {
      btn.classList.remove("loading")
    })
    
    const button = event.currentTarget
    button.classList.add("loading")
    
    // Optional: Add a loading indicator
    this.showLoading()
  }

  showLoading() {
    // Find the products frame and add a loading state
    const frame = document.getElementById("products_list")
    if (frame) {
      frame.classList.add("opacity-50", "pointer-events-none")
    }
  }

  hideLoading() {
    const frame = document.getElementById("products_list")
    if (frame) {
      frame.classList.remove("opacity-50", "pointer-events-none")
    }
  }

  // Called after Turbo Frame loads
  frameLoaded() {
    this.hideLoading()
  }
}
