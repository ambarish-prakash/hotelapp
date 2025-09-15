Rails.application.configure do
  config.x.procurement_sources = config_for(:procurement_sources).deep_symbolize_keys
end
