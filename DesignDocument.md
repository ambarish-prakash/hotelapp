# Design Document
Document explain design decisions made, tradeoffs, and features added.


# ERD
Insert ERD later


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
- Additional column
- Changes in serializer and endpoints that expect this hotel code as the id


### Booking Conditions as text
I've kept this as a text column and told the Rails model to serialize it using JSON as it is ideally provided as a list of conditions.

### Constraints
Over multiple models, I've added constraints to ensure model validity. For example, a unique constrain on the Hotel Code + Source for RawHotel, a not null constrain on Destination for both Hotel and RawHotel, etc

### Images
I'm not using a file store as the images are provided as URL links. However it has a lot of use of actually downloading the image and saving it on our side using ActiveStorage in S3 or so. 


# Workflow
The overall workflow can be divided into two parts - Procurement & Merging the Data, as well as Delivering the Data. By seperating the data loading part from the data fetching, we can improve the cleanliness, maintainability and scalability. The loading is able to sanitize clean and merge data as and when it arrives, and the delivery part just assumes up to date information is present.

## Procurement & Merging:

Workflow diagrams:


### Key Design Decisions

