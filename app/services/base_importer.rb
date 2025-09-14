# frozen_string_literal: true

require 'net/http' # Add this
require 'uri'      # Add this

class BaseImporter
  private

  def self.parse_float(val)
    return nil if val.blank?
    Float(val) rescue nil
  end

  def self.update_location(raw_hotel, lat:, lng:, address:, city:, country:)
    location = raw_hotel.location || raw_hotel.build_location
    location.latitude  = parse_float(lat)
    location.longitude = parse_float(lng)
    location.address   = address.to_s.strip
    location.city      = city.to_s.strip
    location.country   = country.to_s.strip
  end

  def self.sync_amenities(raw_hotel, amenity_keywords)
    new_amenity_attrs = (amenity_keywords || []).map do |amenity_keyword|
      sanitized_keyword = amenity_keyword.to_s.strip.downcase.delete(" ")
      amenity_data = AMENITIES_REVERSE_MAP[sanitized_keyword]
      if amenity_data
        { category: amenity_data[:category], name: amenity_data[:name] }
      else
        Rails.logger.warn("[#{self.name}] No mapping found for amenity: #{amenity_keyword}")
        nil
      end
    end.compact.uniq

    raw_hotel.amenities.delete_all
    
    if new_amenity_attrs.any?
      now = Time.current
      records_to_insert = new_amenity_attrs.map do |attrs|
        attrs.merge(owner_id: raw_hotel.id, owner_type: 'RawHotel', created_at: now, updated_at: now)
      end
      Amenity.insert_all(records_to_insert)
    end
  end

  def self.sync_images(raw_hotel, images_data)
    new_image_attrs = []
    (images_data || {}).each do |category, images|
      images.each do |image_data|
        image_url = image_data["url"]
        if image_url.present? && validate_image_url(image_url) # Add validation here
          new_image_attrs << {
            category: category.to_s,
            url: image_url,
            description: image_data["description"]
          }
        else
          Rails.logger.warn("[#{self.name}] Skipping invalid or inaccessible image URL for RawHotel ID #{raw_hotel.id}: #{image_url}")
        end
      end
    end

    raw_hotel.images.delete_all

    if new_image_attrs.any?
      now = Time.current
      records_to_insert = new_image_attrs.map do |attrs|
        attrs.merge(owner_id: raw_hotel.id, owner_type: 'RawHotel', created_at: now, updated_at: now)
      end
      Image.insert_all(records_to_insert)
    end
  end

  # New helper method for URL validation
  def self.validate_image_url(url)
    uri = URI.parse(url)
    # Only allow HTTP/HTTPS schemes
    return false unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)

    # Set a timeout for the request to prevent hanging
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', read_timeout: 5, open_timeout: 5) do |http|
      response = http.head(uri.path.empty? ? '/' : uri.path)
      return response.is_a?(Net::HTTPSuccess) # Check for 2xx response
    rescue Net::ReadTimeout, Net::OpenTimeout, Errno::ECONNREFUSED, SocketError => e
      Rails.logger.error("[#{self.name}] Error accessing image URL #{url}: #{e.message}")
      return false
    end
  rescue URI::InvalidURIError => e
    Rails.logger.error("[#{self.name}] Invalid image URL format: #{url}: #{e.message}")
    return false
  end
end
