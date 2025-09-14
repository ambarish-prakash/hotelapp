import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  

  connect() {
    console.log('Stimulus Controller Dataset:', this.element.dataset); // Add this line
    if (typeof L === 'undefined') {
      console.error("Leaflet.js not loaded.");
      return;
    }

    const latitude = parseFloat(this.element.dataset.leafletMapLatitudeValue);
    const longitude = parseFloat(this.element.dataset.leafletMapLongitudeValue);
    console.log('Stimulus Controller Latitude:', latitude);
    console.log('Stimulus Controller Longitude:', longitude);
    if (isNaN(latitude) || isNaN(longitude)) {
      console.warn("Latitude or Longitude not provided or invalid for map initialization.");
      return;
    }

    const map = L.map(this.element).setView([latitude, longitude], 15);

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
    }).addTo(map);

    L.marker([latitude, longitude]).addTo(map)
      .bindPopup('Hotel Location')
      .openPopup();
  }
}