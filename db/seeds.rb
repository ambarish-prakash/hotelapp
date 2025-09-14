Destination.find_or_create_by!(id: 5432) do |d|
  d.name = "Singapore"
end

Destination.find_or_create_by!(id: 1122) do |d|
  d.name = "Tokyo"
end
