import { Application } from "@hotwired/stimulus"
import DestinationFilterController from "controllers/destination_filter_controller"
import LeafletMapController from "controllers/leaflet_map_controller"

const application = Application.start()
application.register("destination-filter", DestinationFilterController)
application.register("leaflet-map", LeafletMapController)