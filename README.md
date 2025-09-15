# Hotel Application

This is a Ruby on Rails application designed to manage hotel information, including destinations, amenities, images, and locations. It provides an API for fetching hotel data with filtering capabilities.

## Installation

Follow these steps to set up the application locally:

1.  **Clone the repository:**
    ```bash
    git clone <repository_url>
    cd hotelapp
    ```

2.  **Install Ruby dependencies:**
    ```bash
    bundle install
    ```

3.  **Install Redis:**
    Redis is required for Sidekiq (background job processing). If you don't have Redis installed, you can typically install it via your system's package manager:

    *   **macOS (using Homebrew):**
        ```bash
        brew install redis
        brew services start redis
        ```
    *   **Ubuntu/Debian:**
        ```bash
        sudo apt update
        sudo apt install redis-server
        sudo systemctl enable redis-server
        sudo systemctl start redis-server
        ```
    *   **Other systems:** Refer to the [Redis documentation](https://redis.io/docs/getting-started/installation/) for installation instructions.

4.  **Database Setup:**
    Create and migrate the database:
    ```bash
    rails db:create
    rails db:migrate
    rails db:seed
    ```

5.  **Sidekiq (for background jobs):**
    Sidekiq is used for processing background jobs (e.g., hotel procurement, merging). Ensure Redis is running on your system, as Sidekiq uses it as a backend.

## Running the Application

1.  **Start Sidekiq:**
    In a separate terminal, start the Sidekiq worker:
    ```bash
    bundle exec sidekiq -C config/sidekiq.yml
    ```
    The sidekiq worker has been configured to run cron jobs daily to load data from three different sources.
    Instead if you would like to manually trigger the jobs to populate the database, you can run the following Rake task:
    ```bash
    rake setup:populate_data
    ```
    This task will procure data from all sources and merge the data for a predefined set of hotels.

2.  **Start the Rails Server:**
    In another terminal, start the Rails web server:
    ```bash
    rails s
    ```
    The application will be accessible at `http://localhost:3000`.

## API Endpoints for Hotels

The following API endpoints are available for managing hotel data:

### 1. List Hotels

Retrieves a list of hotels, with optional filtering.

*   **URL:** `/hotels`
*   **Method:** `GET`
*   **Query Parameters:**
    *   `hotel_ids`: (Optional) A comma-separated string of hotel codes (e.g., `hotel_ids=CodeOne,CodeTwo`) to filter hotels by their unique codes.
    *   `destination_id`: (Optional) The ID of a destination to filter hotels by.
*   **Example Request (all hotels):**
    ```bash
    curl -X GET "http://localhost:3000/hotels" \
         -H "Accept: application/json"
    ```
*   **Example Request (filtered by hotel codes):**
    ```bash
    curl -X GET "http://localhost:3000/hotels?hotel_ids=CodeOne,CodeTwo" \
         -H "Accept: application/json"
    ```
*   **Example Request (filtered by destination ID):**
    ```bash
    curl -X GET "http://localhost:3000/hotels?destination_id=1" \
         -H "Accept: application/json"
    ```
*   **Example Request (filtered by hotel codes and destination ID):**
    ```bash
    curl -X GET "http://localhost:3000/hotels?hotel_ids=CodeOne&destination_id=1" \
         -H "Accept: application/json"
    ```

### 2. Show Hotel Details

Retrieves details for a single hotel.

*   **URL:** `/hotels/:id` (where `:id` is the database ID of the hotel)
*   **Method:** `GET`
*   **Example Request:**
    ```bash
    curl -X GET "http://localhost:3000/hotels/1" \
         -H "Accept: application/json"
    ```
    **Note:** The `:id` here refers to the internal database ID of the hotel, not the `hotel_code` used for filtering in the index action. The JSON response for a single hotel will return the `hotel_code` as its `id` attribute due to serializer configuration.

## Frontend

The frontend uses Stimulus.js for dynamic interactions. The destination filter on the `/hotels` page now uses `destination_id` for filtering, aligning with the backend API changes.
