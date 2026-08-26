const state = { items: [], remaining: 0, locked: false, claimAllLabel: "CLAIM ALL REWARDS" };
const resourceName = GetParentResourceName();
const post = (endpoint, body = {}) => fetch(`https://${resourceName}/${endpoint}`, { method: "POST", body: JSON.stringify(body) });

const formatTime = (seconds) => {
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  return `${hours}h ${minutes}m`;
};

const updateControls = () => {
  const cooldown = document.getElementById("cooldown");
  const claimAllButton = document.getElementById("claimAllButton");
  const isReady = state.remaining <= 0 && !state.locked;
  cooldown.textContent = isReady ? "Ready to claim" : `Next claim in ${formatTime(state.remaining)}`;
  cooldown.className = isReady ? "text-[10px] font-semibold text-emerald-400" : "text-[10px] font-semibold text-amber-400";
  claimAllButton.disabled = !isReady;
  claimAllButton.textContent = isReady ? state.claimAllLabel : "COOLDOWN ACTIVE";
  document.querySelectorAll(".claim-button").forEach((button) => {
    button.disabled = !isReady;
    button.textContent = isReady ? "CLAIM" : "LOCKED";
  });
};

const render = () => {
  const container = document.getElementById("items");
  container.innerHTML = state.items.map((item) => `
    <article class="group flex items-center gap-3 rounded border border-white/10 bg-[#191b21] p-2.5 transition hover:border-sky-400/40 hover:bg-[#20232b]">
      <div class="flex h-12 w-12 shrink-0 items-center justify-center overflow-hidden rounded border border-white/10 bg-black/25">
        <img class="h-10 w-10 object-contain transition duration-200 group-hover:scale-105" src="${item.image}" alt="${item.label}" onerror="this.style.display = &quot;none&quot;">
      </div>
      <div class="min-w-0 flex-1">
        <div class="flex items-center justify-between gap-2">
          <h2 class="truncate font-display text-xs font-semibold text-white">${item.label}</h2>
          <span class="shrink-0 rounded bg-white/10 px-1.5 py-0.5 text-[10px] font-bold text-white/60">×${item.amount}</span>
        </div>
        <p class="mt-0.5 truncate text-[10px] text-white/40">${item.description}</p>
      </div>
      <button class="claim-button shrink-0 rounded bg-sky-500 px-2.5 py-2 text-[10px] font-bold text-white transition hover:bg-sky-400 disabled:cursor-not-allowed disabled:bg-white/10 disabled:text-white/30" data-index="${item.index}" type="button">CLAIM</button>
    </article>
  `).join("");
  updateControls();
};

const closeUI = () => post("close");
const claimAll = () => {
  if (state.locked || state.remaining > 0) return;
  state.locked = true;
  render();
  post("claimAll");
};

document.getElementById("closeButton").addEventListener("click", closeUI);
document.getElementById("claimAllButton").addEventListener("click", claimAll);
document.getElementById("items").addEventListener("click", (event) => {
  const button = event.target.closest(".claim-button");
  if (!button || state.locked) return;
  state.locked = true;
  render();
  post("claim", { index: Number(button.dataset.index) });
});

document.addEventListener("keydown", (event) => {
  if (event.key === "Escape") closeUI();
});

window.addEventListener("message", (event) => {
  const { action, data } = event.data;
  if (action === "open") {
    state.items = data.items;
    state.remaining = data.remaining;
    state.locked = false;
    state.claimAllLabel = data.claimAllLabel || "CLAIM ALL REWARDS";
    document.getElementById("title").textContent = data.title;
    document.getElementById("subtitle").textContent = data.subtitle || "Claim individual rewards or collect the full daily allocation.";
    document.getElementById("claimAllButton").textContent = state.claimAllLabel;
    document.body.classList.remove("opacity-0", "pointer-events-none");
    document.body.classList.add("opacity-100", "pointer-events-auto");
    render();
  }
  if (action === "claimed") {
    state.remaining = data.remaining;
    state.locked = false;
    updateControls();
  }
  if (action === "claimFailed") {
    state.remaining = data.remaining || state.remaining;
    state.locked = false;
    updateControls();
  }
  if (action === "close") {
    document.body.classList.add("opacity-0", "pointer-events-none");
    document.body.classList.remove("opacity-100", "pointer-events-auto");
  }
});

setInterval(() => {
  if (state.remaining > 0) {
    state.remaining -= 1;
    updateControls();
  }
}, 1000);
