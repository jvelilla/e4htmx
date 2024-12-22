# HTMX Out-of-Band Swaps Explained

The following HTMX OOB patterns are demonstrated in our application:

1. `hx-swap-oob="true"`
   ```html
   <div id="target2" hx-swap-oob="true">
       new 2
   </div>
   ```
   - Replaces content of element with id="target2"
   - Uses innerHTML swap by default
   - Original target still receives main response content

2. `hx-swap-oob="afterend"`
   ```html
   <div id="target2" hx-swap-oob="afterend">
       <div>after 2</div>
   </div>
   ```
   - Adds content after the element with id="target2"
   - Demonstrates positional swapping
   - Useful for inserting adjacent content

3. `hx-swap-oob="innerHTML:#target3"`
   ```html
   <div hx-swap-oob="innerHTML:#target3">new 3</div>
   ```
   - Alternative syntax using selector
   - Directly specifies both swap type and target
   - Equivalent to using id attribute with "true"

# HTMX Event Triggering Patterns Explained

Our application demonstrates three types of server-triggered events:

1. Simple Event (No Data):
   ```html
   HX-Trigger: event1
   ```
   - Triggers basic event with no payload
   - Client handles with: `hx-on:event1="handleEvent1(event)"`
   - Simplest form of event triggering

2. Event with String Data:
   ```html
   HX-Trigger: {"event2":"some string"}
   ```
   - Passes string data with the event
   - Client receives data in event.detail.value
   - Useful for simple message passing

3. Event with Object Data:
   ```html
   HX-Trigger: {"event3":{"foo":1,"bar":2}}
   ```
   - Passes complex JSON object
   - Client receives nested data structure
   - Enables rich data transfer

Client-side Event Handling:
```javascript
// Simple event handler
function handleEvent1(event) {
    const {value} = event.detail;
    alert('got event1 with ' + value);
}

// String data handler
function handleEvent2(event) {
    const {value} = event.detail;
    alert('got event2 with ' + JSON.stringify(value));
}

// Object data handler
function handleEvent3(event) {
    const {detail} = event;
    delete detail.elt;  // Remove circular reference
    alert('got event3 with ' + JSON.stringify(detail));
}
```

Event Listener Setup:
```html
<body
    hx-on:event1="handleEvent1(event)"
    hx-on:event2="handleEvent2(event)"
    hx-on:event3="handleEvent3(event)"
>
```

Together, these patterns enable:
1. Multiple DOM updates from a single request
2. Server-triggered events with various data types
3. Clean separation of concerns
4. Rich client-server interaction
5. Progressive enhancement

All examples are directly from our working implementation! 