# frozen_string_literal: true

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
    location.address   = address.to_s.strip.presence
    location.city      = city.to_s.strip.presence
    location.country   = country.to_s.strip.presence
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
        new_image_attrs << {
          category: category.to_s,
          url: image_data["url"],
          description: image_data["description"]
        }
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
end
