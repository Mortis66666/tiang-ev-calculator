# 🧮 Tiang EV Calculator

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![Status: Stable](https://img.shields.io/badge/Status-Stable-success.svg)](#)
[![Platform: Web](https://img.shields.io/badge/Platform-Web-orange.svg)](#)

> **Tiang**, also known as *In-Between*, is a probability-based card game. This tool calculates the **Expected Value (EV)** of your hand, helping you make statistically informed decisions.

---

## ✨ Features

- **Dual Modes:**
  - 🗑️ **Discard Mode:** Track cards played by others to keep the deck count accurate.
  - 🧮 **Calculator Mode:** Select your two cards to instantly see the EV.
- **Dynamic Configuration:**
  - Support for multiple decks.
  - Custom card ordering (e.g., A-K or 2-A).
- **User-Friendly Interface:**
  - **Dark Mode** support for late-night sessions.
  - **Undo/Redo** functionality.
  - **Mobile-Responsive** design.

## 🚀 Quick Start

### 🌐 Web Version
No installation required! Just open the `index.html` file in your browser.

```bash
# Clone the repository
git clone https://github.com/yourusername/tiang-ev-calculator.git

# Navigate to the directory
cd tiang-ev-calculator

# Open in browser (Linux)
xdg-open index.html
# macOS
open index.html
# Windows
start index.html
```

### 💻 Terminal Version
For those who prefer the command line, `tiang.sh` provides a fully featured terminal interface.

**Instant Run (via curl):**
```bash
curl -fsSL https://raw.githubusercontent.com/yourusername/tiang-ev-calculator/master/tiang.sh | bash
```

**Run Locally:**
```bash
chmod +x tiang.sh
./tiang.sh
```

## 📖 How to Use

1.  **Setup:** Launch the app and configure the **Number of Decks** and **Card Order**.
2.  **Tracking (Discard Mode):**
    - Tap cards as they are played by other players to remove them from the deck.
    - The counter on each card shows how many are left.
3.  **Calculating (Calculator Mode):**
    - Click the top bar to switch to **Calculator Mode**.
    - Select your two "Tiang" cards (the gateposts).
    - The App will display the **EV** based on the remaining cards in the deck.
    - Tap the top bar again to return to Discard Mode.

## 🧠 The Math

The Expected Value (EV) is calculated using the following formula:

$$
EV = \frac{2 \times \text{Win Outs} - \text{Tiang Outs}}{\text{Total Remaining Cards}} - 1
$$

*   **Win Outs:** Cards strictly between your two selected cards.
*   **Tiang Outs:** Cards matching one of your selected cards (if the game rules penalize hitting the post).
*   **Total Remaining:** Cards left in the deck(s) after accounting for discards and your current hand.

## 🛠️ Tech Stack

- **HTML5** & **CSS3** (with CSS Variables & Flexbox/Grid)
- **Vanilla JavaScript** (ES6+)
- **LocalStorage** for saving preferences.

## 📄 License

This project is licensed under the GNU Affero General Public License v3.0 - see the [LICENSE](LICENSE) file for details.
Check [NOTICE](NOTICE) for license as well.

---

> **Disclaimer:** This calculator is intended for **educational and entertainment purposes only**. It does not guarantee winnings and should not be used for gambling. Please play responsibly.
