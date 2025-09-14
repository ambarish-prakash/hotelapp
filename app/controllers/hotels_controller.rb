class HotelsController < ApplicationController
  def index
    @hotels = Hotel.all.includes(:location, :amenities, :images)

    if params[:hotel_ids].present?
      hotel_ids = params[:hotel_ids].split(',').map(&:strip)
      @hotels = @hotels.where(hotel_code: hotel_ids)
    end

    if params[:destination_id].present?
      @hotels = @hotels.where(destination_id: params[:destination_id])
    end

    respond_to do |format|
      format.html
      format.json { render json: @hotels, each_serializer: HotelSerializer }
    end
  end

  def show
    @hotel = Hotel.includes(:location, :amenities, :images).find(params[:id])

    respond_to do |format|
      format.html
      format.json { render json: @hotel, serializer: HotelSerializer }
    end
  end
end
