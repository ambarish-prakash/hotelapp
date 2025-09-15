# Design Document
Document explain design decisions made, tradeoffs, and features added.


# ERD
![HotelApp_ERD](https://github.com/user-attachments/assets/86d184c9-eb51-4de2-89f4-504e4c0516d8)


## Key Decisions:

### SQL vs NoSQL
For the main reason of ease of setup and execution I went with a SQLite database. Not only that, relational tables enforce structure, which means the Response Output would be more stable / fixed.
On the other hand there is an option of a NoSQL DB such as Mongo. Given the nature of the problem, it looks like multiple sources may have different fields (say tomorrow source D comes and also provides proximity to major attractions), NoSQL would be able to handle that with minimal change. It is a tradeoff worth considering based on the problem - are we adding many new sources? can the downstream handle additional fields / want them?


### Hotel and RawHotel Models
I created a RawHotel model to store the sanitizied and transformed raw inputs from the sources and a Hotel model that could store the merged Hotel object. I kept Location, Amenities and Images separate models, but with polymorphic owners, pointing to either Hotels or RawHotels. The tradeoffs of keeping these two copies can be seen below:

Advantages:
- Clean separation
- Easier debugging as input from the source along with their json input is stored
- Makes merging re runnable as data from sources is saved

Disadvantages:
- Extra sapce. Each value is duplicated and stored


NOTE: Another alternate would be to keep the Hotel as a view itself in the DB. This would save storage, always be up to date and be effeciently handled by the DB engine. However the complexity of the rules will not be as good as being able to prgramatically run code as well as having all the logic in the same repository vs some here and some in the DB.


### Hotel Code as a new field and not the primary key
This might be a bit more contreversial. The hotel ids in the different data sources are strings. While it is very possible to keep the id for the table as a string, there are a few disadvantages such as RawHotel having to have the Id and Source as the PK. I've listed other tradeoffs below. In lieu of these I chose to keep HotelCode as a separate field with an index on it.

Advantage of separate field:
- Incremental Integer Ids for DB objects as is standard common practice
- Logically more sensible for RawHotel to have an Id as its just a parsed object and there are multiple RawHotels for the same Hotel Code (from different sources)

Disadvantages:
- Additional column, extra index
- Changes in serializer and endpoints that expect this hotel code as the id (Nomenclature change)


### Booking Conditions as text
I've kept this as a text column and told the Rails model to serialize it using JSON as it is ideally provided as a list of conditions.

### Constraints
Over multiple models, I've added constraints to ensure model validity. For example, a unique constrain on the Hotel Code + Source for RawHotel, a not null constrain on Destination for both Hotel and RawHotel, etc
These can be see in the DB Schema as well as Model level.

### Images
I'm not using a file store as the images are provided as URL links.
However with scale it is better to download the image and save it on our side using ActiveStorage in S3 or so as that reduces the dependency on the external platforms CDN.


# Workflow
The overall workflow can be divided into two parts - Procurement & Merging the Data, as well as Delivering the Data. By seperating the data loading part from the data fetching, we can improve the cleanliness, maintainability and scalability. The loading is able to sanitize clean and merge data as and when it arrives, and the delivery part just assumes up to date information is present.

## Procurement & Merging:

### Workflow diagrams:
### Procurement
![HotelApp_Procurement](https://github.com/user-attachments/assets/64289e39-2f21-4df0-852e-1e6c8a20243a)

### Merging
![HotelApp_Merge](https://github.com/user-attachments/assets/5e9be7d0-4f5a-4aeb-9973-2303e6b1067e)

### Delivery of Data
This is a standard Rails controller with an index and show endpoint, to serve Hotel objects via a serializer.


## Key Design Decisions

### Background / Async Jobs for Procurement / Merging
I wanted to decouple the Procurement with the data delivery. This allows them to run independently which is important as the data procurement is dependent on external systems and hence can face errors out of our control. 

### Hotel Importer Extensions
The Hotel importers are written in a way that is easy to extend to new data sources. Common sanitization and validation is handled at the base level, while source specific implementation is written in the corrsponding classes to help map the input JSON to a common RawHotel model on our end.

### Hotel Merge Service Separation
Each attribute of the hotels have a separate Merge service, which allows separation of responsibility and a common area for specific merging logic per field.

### "" vs nil for empty / missing fields
For a lot of the string fields (address, description, etc) I decided to import them as "" instead of nil values. Both methods are viable and the pros/cons are listed below. However for uniformity I chose to use empty strings.

Advantages:
- Uniformity and assurance of not facing possible NoMethodError on nil objects
- Raw JSON is still stored and hence possible to verify integrity of input data

Disadvantages:
- nil can help differentiate between empty "" and missing fields (nil)
- nil is used for latitude and logitude anyways, as using 0.0 for them does not signify invalid / empty attribute.


# Other Noteable Features
Here are some additional features added in:
- Different merge logic implemented (values from latest updated element / largest sized string / majority agreement / deduped aggregation).
- Default amenities set up as part of config. Import jobs transform source values into fixed internal values (eg laundry mapped to Dry Cleaning).
- Image URL validation. Ensure image endpoint can be accessed while sanitization of input.
- Cron job setup to ensure daily trigger of job fetching.
- Test pipeline included as part of CI (on Pull Request and Push to Main). Unit tests written for all services, jobs and controller.
- UI (I somehow assumed a UI was required to deliver the data, but only when reading it later I realized only the endpoint was enough).


# Future Implmentation
These are a mix of features to be implemented now / considered for the future:
- Image deduplication using advanced techniques such as embeddings or phashes
- Deletion currently does not work. If hotels are removed from a source, its RawHotel object in the DB is not removed.
- If possible check to see if source URLs could be queried with timestamp, to only fetch latest updates
- Unmatched Amenities (dont have mapping to our internal set) log a warning. Make alerts based on that to handle new amenity tags

