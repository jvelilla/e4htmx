# HTMX Form Attributes Explained

The following HTMX attributes are used in our dog creation form:

1. `hx-post="/dog"`
   - This tells HTMX to make a POST request to the `/dog` endpoint when the form is submitted
   - The form data (name and breed) will be automatically sent as form data in the request

2. `hx-disable-elt="#add-btn"`
   - During the AJAX request, this will disable the button with id="add-btn"
   - This prevents double-submissions while the request is in progress
   - The button will automatically re-enable when the request completes

3. `hx-target="table tbody"`
   - Specifies where the response content should be inserted
   - In this case, it targets the `<tbody>` element inside the table
   - The server's response should be HTML that fits within a table body

4. `hx-swap="afterbegin"`
   - Defines how the response content should be inserted into the target
   - `afterbegin` means the new content will be inserted at the beginning of the target element
   - This makes new dogs appear at the top of the table rather than the bottom

5. `hx-on:htmx:after-request="this.reset()"`
   - This is an event listener that runs after the request completes
   - `this.reset()` calls the form's reset method
   - It clears all the form inputs after a successful submission

Together, these attributes create a smooth user experience where:
1. User fills out the form
2. Submits it (button disables)
3. Server processes the request
4. New dog appears at top of table
5. Form clears
6. Button re-enables

All of this happens without a page refresh!

# HTMX Table Attributes Explained

The following HTMX attributes are used in our dog listing table:

1. `hx-trigger="revealed"`
   - This triggers the AJAX request when the element becomes visible in the viewport
   - It's useful for lazy loading content as the user scrolls
   - The alternative version `hx-trigger="load"` would fetch immediately when the page loads

2. `hx-get="/table-rows"`
   - Makes a GET request to the `/table-rows` endpoint
   - This endpoint should return HTML containing the table rows with dog data

3. `hx-target="tbody"`
   - Specifies where the response HTML should be inserted
   - In this case, it targets the empty `<tbody>` element
   - The server response will be placed inside this tbody

Together, these attributes create a lazy-loading table that:
1. Waits until the table scrolls into view
2. Fetches the dog data from the server
3. Inserts the returned HTML rows into the table body

This is a common pattern for performance optimization, especially with large datasets, as it:
- Reduces initial page load time
- Only loads data when needed
- Provides a smooth user experience

The table works in conjunction with the form above it, which adds new dogs to the beginning of the table using different HTMX attributes (`hx-post`, `hx-swap="afterbegin"`). 