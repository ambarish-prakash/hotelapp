import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select"]

  connect() {
    this.fetchDestinations()
  }

  async fetchDestinations() {
    try {
      const response = await fetch("/destinations")
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      const destinations = await response.json()
      this.populateSelect(destinations)
    } catch (error) {
      console.error("Error fetching destinations:", error)
    }
  }

  populateSelect(destinations) {
    // Add the default "All Destinations" option
    const allOption = document.createElement("option")
    allOption.value = "All Destinations"
    allOption.textContent = "All Destinations"
    this.selectTarget.appendChild(allOption)

    destinations.forEach(destination => {
      const option = document.createElement("option")
      option.value = destination.id
      option.textContent = destination.name
      this.selectTarget.appendChild(option)
    })

    // Set the selected value if it was present in the URL params
    const urlParams = new URLSearchParams(window.location.search)
    const selectedDestination = urlParams.get("destination_id")
    if (selectedDestination) {
      this.selectTarget.value = selectedDestination
    }
  }
}
