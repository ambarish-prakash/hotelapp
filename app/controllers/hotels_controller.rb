class HotelsController < ApplicationController
  def index
    @destinations = Destination.all
    @hotels = Hotel.all.includes(:location)

    if params[:destination_name].present? && params[:destination_name] != "All Destinations"
      destination = Destination.find_by(name: params[:destination_name])
      if destination
        @hotels = @hotels.where(destination_id: destination.id)
      else
        @hotels = Hotel.none # No hotels if destination not found
      end
    end

    respond_to do |format|
      format.html # Renders app/views/hotels/index.html.erb
      format.json do
        render json: @hotels.map { |hotel|
          {
            id: hotel.id,
            name: hotel.name,
            destination: {
              id: hotel.destination.id,
              name: hotel.destination.name
            }
          }
        }
      end
    end
  end

  def show
    @hotel = Hotel.includes(:location, :amenities, :images).find(params[:id])

    respond_to do |format|
      format.html # Renders app/views/hotels/show.html.erb
      format.json { render json: @hotel, serializer: HotelSerializer }
    end
  end
end