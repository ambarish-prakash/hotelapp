AMENITIES = YAML.load_file(
  Rails.root.join("config", "amenities.yml")
).with_indifferent_access.freeze
