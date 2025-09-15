require "test_helper"

RawHotelStub = Struct.new(:hotel_code, :source)

# Using Mocha to mock for this test as default Minitest raised errors when stubbing an ActiveJob
class HotelProcurementJobTest < ActiveJob::TestCase
  test "calls HotelMergeJob.perform_later for each imported hotel" do
    source      = "test_source"
    hotel_data  = [ { "Id" => "HC1" }, { "Id" => "HC2" }, { "Id" => "HC3" } ]
    importer    = mock("importer")

    # Don't touch Rails.config — stub the endpoint lookup
    HotelProcurementJob.any_instance.expects(:fetch_endpoint!).with(source).returns("http://fake.endpoint")

    # Fetcher returns the raw JSON-ish items
    Procurement::Fetcher.expects(:call).with("http://fake.endpoint").returns(hotel_data)

    # Importer for this source
    Procurement::Importers.expects(:for).with(source).returns(importer)

    # Each JSON item is imported -> returns something with #hotel_code and #source
    importer.expects(:import).with({ "Id" => "HC1" }).returns(RawHotelStub.new("HC1", source))
    importer.expects(:import).with({ "Id" => "HC2" }).returns(RawHotelStub.new("HC2", source))
    importer.expects(:import).with({ "Id" => "HC3" }).returns(RawHotelStub.new("HC3", source))

    # And for each imported record we schedule a merge
    HotelMergeJob.expects(:perform_later).with("HC1")
    HotelMergeJob.expects(:perform_later).with("HC2")
    HotelMergeJob.expects(:perform_later).with("HC3")

    # Run the job inline (no adapters involved)
    HotelProcurementJob.new.perform(source)
  end

  test "logs & skips a failed import but continues with the rest" do
    source     = "test_source"
    hotel_data = [ { "Id" => "HC1" }, { "Id" => "BAD" }, { "Id" => "HC3" } ]
    importer   = mock("importer")

    HotelProcurementJob.any_instance.expects(:fetch_endpoint!).with(source).returns("http://fake.endpoint")
    Procurement::Fetcher.expects(:call).with("http://fake.endpoint").returns(hotel_data)
    Procurement::Importers.expects(:for).with(source).returns(importer)

    importer.expects(:import).with({ "Id" => "HC1" }).returns(RawHotelStub.new("HC1", source))
    importer.expects(:import).with({ "Id" => "BAD" }).raises(StandardError.new("boom"))
    importer.expects(:import).with({ "Id" => "HC3" }).returns(RawHotelStub.new("HC3", source))

    # Warnings for the failed one
    Rails.logger.expects(:warn).with(regexp_matches(/Procurement for hotel/))
    Rails.logger.expects(:warn).with(regexp_matches(/Skipping item due to .*boom/))

    # Merge jobs only for the successful imports
    HotelMergeJob.expects(:perform_later).with("HC1")
    HotelMergeJob.expects(:perform_later).with("HC3")
    HotelMergeJob.expects(:perform_later).with("BAD").never

    HotelProcurementJob.new.perform(source)
  end
end
