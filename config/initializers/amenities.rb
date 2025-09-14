AMENITIES = YAML.load_file(
  Rails.root.join("config", "amenities.yml")
).with_indifferent_access.freeze

AMENITIES_REVERSE_MAP = AMENITIES.each_with_object({}) do |(category, amenities), reverse_map|
  amenities.each do |amenity_name, variations|
    variations.each do |variation|
      sanitized_variation = variation.to_s.strip.downcase.delete(" ")
      reverse_map[sanitized_variation] = { category: category, name: amenity_name }
    end
  end
end.freeze
