namespace :setup do
  desc "Populates the database with hotel data from all sources."
  task populate_data: :environment do
    puts "Populating data from all sources..."

    # Procure data from all sources
    puts "- Procuring data from Acme..."
    HotelProcurementJob.perform_now("acme")
    puts "- Procuring data from Patagonia..."
    HotelProcurementJob.perform_now("patagonia")
    puts "- Procuring data from Paperflies..."
    HotelProcurementJob.perform_now("paperflies")

    # Merge data for specific hotels
    puts "- Merging data for specific hotels..."
    HotelMergeJob.perform_now("iJhz")
    HotelMergeJob.perform_now("SjyX")
    HotelMergeJob.perform_now("f8c9")

    puts "Data population complete."
  end
end
