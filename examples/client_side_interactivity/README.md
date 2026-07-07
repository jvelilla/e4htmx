# Client-Side Interactivity Example

This example demonstrates how to add client-side interactivity to an application using two lightweight JavaScript libraries: **Alpine.js** and **_hyperscript**. These libraries pair perfectly with HTMX, allowing you to implement client-side logic (like toggling elements, form validations, or dynamic styling) without requiring server round trips, all without the overhead of a full Single Page Application (SPA) framework.

## Goal of the Example

The example features a "Temperature Slider" application implemented twice:
1. **Alpine.js Version**: Uses attributes like `x-data`, `x-on`, and `x-bind`.
2. **_hyperscript Version**: Uses the `_` attribute with English-like syntax.

Both versions listen to changes on an `<input type="range">` slider representing a temperature value (0 to 100). The display updates the text content to show the temperature and changes color dynamically:
- **Blue** if below 32 (freezing).
- **Red** if 85 or above (uncomfortably hot).
- **Green** for values in between.

This showcases how to manage state and manipulate the DOM directly from HTML, complementing HTMX's server interaction model.

## Additional Examples

We have also added the **Score Keeper** examples from the book. They implement a more complex user interface where state changes based on team scores and the "likes" button dynamically changing its border color and icon:
- **[Alpine Score Keeper](www/alpine-score-keeper.html)** 
- **[_hyperscript Score Keeper](www/hyperscript-score-keeper.html)**
