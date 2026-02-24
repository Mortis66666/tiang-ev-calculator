const cardList = document.getElementById("card-list");
const topDiv = document.getElementById("top");
const resetButton = document.getElementById("reset-button");
const undoButton = document.getElementById("undo-button");
const modeText = document.getElementById("mode-text");
const text = document.getElementById("text");
const cells = document.querySelectorAll(".cell");

const deckCount = localStorage.getItem("deckCount") || 1;
const cardOrder = localStorage.getItem("cardOrder") || "A23456789TJQK";

let cardCounter = {};
let tiangs = [];

let discardHistory = [];
let calculatorHistory = [];

let mode = "discard";

function setup() {
    resetCounter();
    updateText();
    updateView();
}

function resetCounter() {
    cardCounter = {};
    for (let i = 1; i <= 13; i++) {
        cardCounter[i] = 4 * deckCount;
    }
}

function updateView() {
    cells.forEach(cell => {
        const value = cell.dataset.value;

        cell.textContent = `${cardOrder[value - 1]} (${cardCounter[value]})`;

        if (tiangs.includes(value)) {
            cell.classList.add("highlight");
        } else {
            cell.classList.remove("highlight");
        }
    });
}

function reset() {
    resetCounter();
    tiangs.length = 0;
    discardHistory.length = 0;
    calculatorHistory.length = 0;
    updateView();
    updateText();
}

function undo() {
    if (mode === "discard") {
        const lastDiscard = discardHistory.pop();
        if (lastDiscard) {
            cardCounter[lastDiscard]++;
        }
    } else if (mode === "calculator") {
        if (tiangs.length == 0) {
            tiangs = calculatorHistory.pop() || [];
            tiangs.pop();
        } else if (tiangs.length == 1) {
            const lastCard = tiangs.pop();
            const cells = document.querySelectorAll(".cell");
            cells.forEach(cell => {
                if (cell.dataset.value === lastCard) {
                    cell.classList.remove("highlight");
                }
            });
            cardCounter[lastCard]++;
        } else {
            alert("Something wrong");
        }
    }
    updateText();
    updateView();
}

function updateText() {
    if (mode === "discard") {
        modeText.textContent = "Discard mode";
        text.innerHTML =
            "In this mode, simply select the cards discarded during other player's turn.<br>Tap here to switch to calculator mode during your turn.";
    } else if (mode === "calculator") {
        modeText.textContent = "Calculator mode";
        if (tiangs.length === 0) {
            text.innerHTML =
                "In this mode, select the cards you wish to calculate EV for.<br>Tap here to switch to discard mode.";
        } else if (tiangs.length === 1) {
            text.innerHTML = `Selected: ${tiangs[0]}`;
        } else if (tiangs.length === 2) {
            calculateEV();

            calculatorHistory.push([...tiangs]);
            tiangs.length = 0;
            updateView();
        }
    }
}

function calculateEV() {
    let winOuts = 0;

    let min = Math.min(...tiangs);
    let max = Math.max(...tiangs);

    for (let i = min + 1; i < max; ++i) {
        winOuts += cardCounter[i];
    }

    let tiangOuts = cardCounter[tiangs[0]];

    if (tiangs[0] != tiangs[1]) {
        tiangOuts += cardCounter[tiangs[1]];
    }

    const totalOuts =
        52 * deckCount - // total cards
        2 - // Current tiangs
        calculatorHistory.length * 2 - // Previous tiangs
        discardHistory.length; // Discarded cards
    const ev = (2 * winOuts - tiangOuts) / totalOuts - 1;
    text.innerHTML = `[${cardOrder[min - 1]}-${cardOrder[max - 1]}] EV: ${ev.toFixed(2)}`;
}

topDiv.addEventListener("click", () => {
    if (mode === "discard") {
        mode = "calculator";
    } else if (mode === "calculator") {
        if (tiangs.length > 0) {
            alert(
                "You have selected cards. Please calculate or undo before switching mode."
            );
            return;
        }

        mode = "discard";
    }
    updateText();
    updateView();
});

cardList.addEventListener("click", event => {
    if (event.target.classList.contains("cell")) {
        const selectedCard = event.target;
        const cardValue = selectedCard.dataset.value;

        if (cardCounter[cardValue] === 0) {
            alert("No more cards of this value left!");
            return;
        }

        if (mode === "discard") {
            discardHistory.push(cardValue);
            cardCounter[cardValue]--;
        } else if (mode === "calculator") {
            if (tiangs.length < 2) {
                tiangs.push(cardValue);
                cardCounter[cardValue]--;
            }
        }

        updateText();
        updateView();
    }
});

resetButton.addEventListener("click", reset);
undoButton.addEventListener("click", undo);

// Keybinds

document.addEventListener("keydown", event => {
    if (event.key === "r") {
        reset();
    } else if (event.key === "u") {
        undo();
    }

    // Ctrl-z

    if (event.ctrlKey && event.key === "z") {
        undo();
    }
});

setup();
