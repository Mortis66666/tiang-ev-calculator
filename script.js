const STORAGE_KEYS = {
    THEME: "theme",
    DECK_COUNT: "deckCount",
    CARD_ORDER: "cardOrder"
};

function initTheme() {
    const savedTheme = localStorage.getItem(STORAGE_KEYS.THEME);
    if (savedTheme) {
        document.documentElement.setAttribute("data-theme", savedTheme);
    }
}

function toggleTheme() {
    const currentTheme = document.documentElement.getAttribute("data-theme");
    let newTheme;

    if (currentTheme) {
        newTheme = currentTheme === "dark" ? "light" : "dark";
    } else {
        const systemDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
        newTheme = systemDark ? "light" : "dark";
    }

    document.documentElement.setAttribute("data-theme", newTheme);
    localStorage.setItem(STORAGE_KEYS.THEME, newTheme);
}

initTheme();

const themeToggleBtn = document.getElementById("theme-toggle");
if (themeToggleBtn) {
    themeToggleBtn.addEventListener("click", toggleTheme);
}

const els = {
    setupForm: document.getElementById("setup-form"),
    cardList: document.getElementById("card-list")
};

if (els.setupForm) {
    const inputs = {
        deckCount: document.getElementById("deck-count"),
        cardOrder: document.getElementById("card-order"),
        customOrder: document.getElementById("custom-card-order")
    };

    if (localStorage.getItem(STORAGE_KEYS.DECK_COUNT)) {
        inputs.deckCount.value = localStorage.getItem(STORAGE_KEYS.DECK_COUNT);
    }

    inputs.cardOrder.addEventListener("change", () => {
        const isCustom = inputs.cardOrder.value === "custom";
        inputs.customOrder.classList.toggle("hidden", !isCustom);
        inputs.customOrder.required = isCustom;
        if (isCustom) inputs.customOrder.focus();
    });

    els.setupForm.addEventListener("submit", (event) => {
        event.preventDefault();

        const deckCount = inputs.deckCount.value;
        let cardOrder = inputs.cardOrder.value;

        if (cardOrder === "custom") {
            cardOrder = inputs.customOrder.value.toUpperCase();
            if (!/^[A23456789TJQK]{13}$/.test(cardOrder)) {
                alert("Invalid order! Please enter exactly 13 characters using: A, 2-9, T, J, Q, K.");
                return;
            }
        }

        try {
            localStorage.setItem(STORAGE_KEYS.DECK_COUNT, deckCount);
            localStorage.setItem(STORAGE_KEYS.CARD_ORDER, cardOrder);
            window.location.href = "calculator.html";
        } catch (e) {
            alert("Error saving settings. Please ensure cookies/local storage is enabled.");
        }
    });
}

if (els.cardList) {
    const CONFIG = {
        DECK_COUNT: parseInt(localStorage.getItem(STORAGE_KEYS.DECK_COUNT)) || 1,
        CARD_ORDER: localStorage.getItem(STORAGE_KEYS.CARD_ORDER) || "A23456789TJQK",
        MODES: { DISCARD: "discard", CALCULATOR: "calculator" },
        TEXTS: {
            DISCARD_MODE: "Discard mode",
            CALCULATOR_MODE: "Calculator mode",
            DISCARD_INSTRUCTIONS: "In this mode, simply select the cards discarded during other player's turn.<br>Tap here to switch to calculator mode during your turn.",
            CALCULATOR_INSTRUCTIONS: "In this mode, select the cards you wish to calculate EV for.<br>Tap here to switch to discard mode.",
            ERROR_SWITCH_MODE: "You have selected cards. Please calculate or undo before switching mode.",
            ERROR_NO_CARDS: "No more cards of this value left!",
            ERROR_GENERIC: "Something wrong"
        }
    };

    const state = {
        cardCounter: {},
        tiangs: [],
        history: { discard: [], calculator: [] },
        mode: CONFIG.MODES.DISCARD
    };

    const UI = {
        cardList: els.cardList,
        topDiv: document.getElementById("top"),
        resetButton: document.getElementById("reset-button"),
        undoButton: document.getElementById("undo-button"),
        modeText: document.getElementById("mode-text"),
        text: document.getElementById("text"),
        cells: Array.from(document.querySelectorAll(".cell"))
    };

    function resetCounter() {
        for (let i = 1; i <= 13; i++) {
            state.cardCounter[i] = 4 * CONFIG.DECK_COUNT;
        }
    }

    function updateUI() {

        UI.cells.forEach(cell => {
            const value = parseInt(cell.dataset.value);
            const count = state.cardCounter[value];
            const isHighlighted = state.tiangs.includes(value);

            const newText = `${CONFIG.CARD_ORDER[value - 1]} (${count})`;
            if (cell.textContent !== newText) cell.textContent = newText;
            cell.classList.toggle("highlight", isHighlighted);
        });

        if (state.mode === CONFIG.MODES.DISCARD) {
            UI.modeText.textContent = CONFIG.TEXTS.DISCARD_MODE;
            UI.text.innerHTML = CONFIG.TEXTS.DISCARD_INSTRUCTIONS;
        } else {
            UI.modeText.textContent = CONFIG.TEXTS.CALCULATOR_MODE;
            if (state.tiangs.length === 0) {

                if (!UI.text.innerHTML.startsWith("[")) {
                    UI.text.innerHTML = CONFIG.TEXTS.CALCULATOR_INSTRUCTIONS;
                }
            } else if (state.tiangs.length === 1) {
                UI.text.innerHTML = `Selected: ${state.tiangs[0]}`;
            }
        }
    }

    function calculateEV() {
        const [t1, t2] = state.tiangs;
        const min = Math.min(t1, t2);
        const max = Math.max(t1, t2);

        let winOuts = 0;
        for (let i = min + 1; i < max; ++i) winOuts += state.cardCounter[i];

        let tiangOuts = state.cardCounter[t1];
        if (t1 !== t2) tiangOuts += state.cardCounter[t2];

        const totalOuts = (52 * CONFIG.DECK_COUNT) - 2 - (state.history.calculator.length * 2) - state.history.discard.length;
        const ev = ((2 * winOuts - tiangOuts) / totalOuts) - 1;

        UI.text.innerHTML = `[${CONFIG.CARD_ORDER[min - 1]}-${CONFIG.CARD_ORDER[max - 1]}] EV: ${ev.toFixed(2)}`;
    }

    function undo() {
        const { mode, tiangs, history, cardCounter } = state;
        if (mode === CONFIG.MODES.DISCARD) {
            const lastDiscard = history.discard.pop();
            if (lastDiscard) cardCounter[lastDiscard]++;
        } else {
            if (tiangs.length === 0) {
                const previousTiangs = history.calculator.pop();
                if (previousTiangs) {
                    state.tiangs = previousTiangs;
                    state.tiangs.pop(); 

                }
            } else if (tiangs.length === 1) {
                cardCounter[tiangs.pop()]++;
            } else {
                alert(CONFIG.TEXTS.ERROR_GENERIC);
            }
        }
        updateUI();
    }

    function reset() {
        resetCounter();
        state.tiangs = [];
        state.history.discard = [];
        state.history.calculator = [];
        updateUI();
    }

    UI.topDiv.addEventListener("click", () => {
        if (state.mode === CONFIG.MODES.DISCARD) {
            state.mode = CONFIG.MODES.CALCULATOR;
        } else {
            if (state.tiangs.length > 0) {
                alert(CONFIG.TEXTS.ERROR_SWITCH_MODE);
                return;
            }
            state.mode = CONFIG.MODES.DISCARD;
        }
        updateUI();
    });

    UI.cardList.addEventListener("click", event => {
        const target = event.target;
        if (!target.classList.contains("cell")) return;

        const val = parseInt(target.dataset.value);
        if (state.cardCounter[val] <= 0) {
            alert(CONFIG.TEXTS.ERROR_NO_CARDS);
            return;
        }

        if (state.mode === CONFIG.MODES.DISCARD) {
            state.history.discard.push(val);
            state.cardCounter[val]--;
            updateUI();
        } else {
            if (state.tiangs.length < 2) {
                state.tiangs.push(val);
                state.cardCounter[val]--;
                if (state.tiangs.length === 2) {
                    calculateEV();
                    state.history.calculator.push([...state.tiangs]);
                    state.tiangs = [];
                }
                updateUI();
            }
        }
    });

    UI.resetButton.addEventListener("click", reset);
    UI.undoButton.addEventListener("click", undo);

    document.addEventListener("keydown", event => {
        if (event.ctrlKey && event.key === "z") { undo(); return; }
        if (event.key.toLowerCase() === "r") reset();
        if (event.key.toLowerCase() === "u") undo();
    });

    resetCounter();
    updateUI();
}

