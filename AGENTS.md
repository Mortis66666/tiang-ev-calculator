# Agentic Coding Guidelines for Tiang EV Calculator

This document provides comprehensive guidelines for AI agents and developers working on the Tiang EV Calculator repository. 
It covers build/run instructions, code style, conventions, and architectural details to ensure consistency and quality.

## 1. Project Overview & Architecture

**Type:** Static Web Application (HTML/CSS/Vanilla JS)
**Purpose:** Calculates Expected Value (EV) for the "Tiang" (In-Between) card game.
**Core Logic:**
- Tracks the state of a deck (or multiple decks).
- Two modes: `discard` (tracking cards played by others) and `calculator` (calculating EV for the player's hand).
- **EV Formula:** `(2 * winOuts - tiangOuts) / totalOuts - 1`.
- **Data Persistence:** Uses `localStorage` for settings like `deckCount` and `cardOrder`.

## 2. Environment & Execution

Since this is a static site with no build step, execution is straightforward.

### Running the Application
- **Local:** Open `index.html` directly in a web browser.
- **Local Server (Recommended):** Use a simple HTTP server to avoid CORS issues (though not strictly necessary for this codebase as it doesn't fetch external resources).
  ```bash
  # Python 3
  python3 -m http.server 8000
  # Node.js (if available)
  npx http-server .
  ```
- **Access:** Navigate to `http://localhost:8000` (or the file path).

### Deployment
- **Platform:** GitHub Pages.
- **Workflow:** `.github/workflows/static.yml` handles deployment automatically on push to `master`.
- **Artifact:** The root directory is uploaded as the artifact.

## 3. Testing & Linting

There is no automated test suite or CI-based linter. All verification is manual or based on local configuration.

### Manual Testing
- **Procedure:** Open the application in a browser after changes.
- **Verification Steps:**
  1.  **Reset:** Click 'Reset' to ensure counters initialize.
  2.  **Discard Mode:** Click cards to simulate discards. Verify counts decrease.
  3.  **Calculator Mode:** Switch mode. Select 2 cards. Verify EV calculation appears.
  4.  **Undo:** Test 'Undo' button and `Ctrl+Z` in both modes.
  5.  **Responsiveness:** Check layout on mobile/desktop viewports.

### Formatting (Prettier)
The project uses a `.prettierrc.json` configuration. Agents *must* adhere to these rules when generating code.

**Configuration:**
```json
{
    "tabWidth": 4,
    "useTabs": false,
    "trailingComma": "none",
    "arrowParens": "avoid"
}
```

- **Indentation:** 4 spaces (Strict).
- **Quotes:** Double quotes `"` are preferred for HTML attributes and JS strings, though JS often uses them interchangeably. Consistency is key.
- **Semicolons:** Always use semicolons.

## 4. Code Style & Conventions

### JavaScript (`script.js`)

**Variable Declaration:**
- Use `const` for immutable references (DOM elements, configuration).
- Use `let` for mutable state (`cardCounter`, `mode`, `tiangs`).
- **Do not** use `var`.

**Naming Conventions:**
- **Variables/Functions:** `camelCase` (e.g., `cardList`, `updateView`, `calculateEV`).
- **Constants:** `UPPER_SNAKE_CASE` is acceptable for magic numbers, but the current codebase mostly uses standard variables.
- **CSS Classes in JS:** String literals matching CSS class names (e.g., `"highlight"`, `"cell"`).

**DOM Interaction:**
- Cache DOM elements at the top of the file using `document.getElementById` or `document.querySelectorAll`.
- Use `addEventListener` for interactions.
- Update the UI by modifying `textContent`, `innerHTML`, or `classList`.

**State Management:**
- State is held in global variables within `script.js` (e.g., `cardCounter`, `calculatorHistory`).
- **Mutation:** Functions like `undo()` and `reset()` directly mutate these globals and then call `updateView()`.
- **Pattern:** Action -> State Update -> `updateView()` -> `updateText()`.

**Functions:**
- Use `function keyword` for top-level declarations (hoisting is relied upon).
- Arrow functions `() => {}` are acceptable for callbacks (e.g., event listeners).
- Keep functions small and focused (e.g., `calculateEV` only calculates, `updateView` only renders).

**Error Handling:**
- Use `alert()` for user-facing errors (e.g., "No more cards of this value left!").
- Fail gracefully if state is invalid (e.g., `tiangs` length checks).

### HTML (`index.html`, `calculator.html`)

- **Structure:** Semantic HTML5.
- **IDs:** Use IDs for unique elements that JS needs to touch (e.g., `id="card-list"`).
- **Classes:** Use classes for styling and grouping (e.g., `class="cell"`).
- **Attributes:** Use `data-*` attributes for storing values associated with DOM elements (e.g., `data-value="1"`).

### CSS (`style.css`)

- **Selectors:** Class selectors preferred over ID selectors for styling.
- **Layout:** Flexbox is used for layout. Use grid if it is easier as in writting less code.
- **Units:** Use appropriate css units. Don't just use `px` for everything, `px` is only for things that require small values.
- Use latest cutting edge css

## 5. Implementation Details for Agents

### Adding New Features
1.  **Modify HTML:** Add necessary elements with IDs.
2.  **Update CSS:** Style the new elements.
3.  **Update JS State:** Add new state variables if needed.
4.  **Update JS Logic:** Add event listeners and logic functions.
5.  **Reflect in View:** Ensure `updateView()` covers the new state.

### Modifying Logic
- **Deck Logic:** Remember that `cardCounter` is 1-indexed (1-13).
- **EV Calculation:** If modifying the formula, comment the math logic clearly.
- **Modes:** Respect the `mode` variable (`discard` vs `calculator`). Ensure logic is gated by the correct mode.

### Common Tasks & Snippets

**Reading State:**
```javascript
const count = cardCounter[cardValue]; // cardValue is 1-13
const currentMode = mode; // "discard" | "calculator"
```

**Updating UI:**
```javascript
function updateCustomElement() {
    const el = document.getElementById("custom");
    el.textContent = someStateValue;
}
// Add to setup() and reset()
```

**Adding a Keybind:**
```javascript
document.addEventListener("keydown", event => {
    if (event.key === "n") { // New action
        performAction();
    }
});
```

## 6. Deprecation & Cleanup

- **Unused Code:** Remove commented-out code unless it serves a documentation purpose.
- **Console Logs:** Remove `console.log` statements before finalizing changes.
- **Comments:** Keep comments focused on *why*, not *what*, especially in complex EV calculation logic.

## 7. Version Control

- **Commit Messages:** Clear and descriptive (e.g., "Fix EV calculation for pairs", "Add reset button styling").
- **Files:** Ensure `script.js`, `style.css`, and `index.html` are always in sync regarding IDs and classes.
