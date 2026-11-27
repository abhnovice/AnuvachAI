const byId = (id) => document.getElementById(id);
const state = { draft: null, tickets: [], selectedTicket: null, transcript: [], partialTurns: {}, live: null };
const names = { en: "English", hi: "Hindi", ta: "Tamil", te: "Telugu", bn: "Bengali", kn: "Kannada", ml: "Malayalam", ur: "Urdu", pa: "Punjabi" };

async function api(path, options = {}) {
  const response = await fetch(path, {
    ...options,
    headers: { "Content-Type": "application/json", ...(options.headers || {}) },
  });
  const body = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error(body.detail || body.error || `HTTP ${response.status}`);
  return body;
}

function showView(name) {
  document.querySelectorAll(".rail-tab").forEach((tab) => {
    const active = tab.dataset.view === name;
    tab.classList.toggle("active", active);
    active ? tab.setAttribute("aria-current", "page") : tab.removeAttribute("aria-current");
  });
  document.querySelectorAll(".view").forEach((view) => {
    const active = view.id === `view-${name}`;
    view.hidden = !active;
    view.classList.toggle("active", active);
  });
  if (name === "admin") refreshTickets();
  if (name === "diagnostics") refreshDiagnostics();
}

document.querySelectorAll(".rail-tab").forEach((tab) => tab.addEventListener("click", () => showView(tab.dataset.view)));

function isRtl(language) { return language === "ur"; }

function renderTranscript() {
  const target = byId("transcript");
  target.replaceChildren();
  const turns = [...state.transcript, ...Object.values(state.partialTurns)];
  if (!turns.length) {
    target.innerHTML = '<p class="empty-state">Your original transcript and any corrections will appear here.</p>';
    return;
  }
  for (const turn of turns) {
    const item = document.createElement("article");
    item.className = `transcript-item ${turn.speaker === "agent" ? "agent" : ""}`;
    item.dir = isRtl(turn.language) ? "rtl" : "auto";
    const label = document.createElement("span");
    label.textContent = `${turn.speaker === "agent" ? "AGENT" : "EMPLOYEE"} · ${names[turn.language] || turn.language}${turn.partial ? " · LIVE" : ""}`;
    const original = document.createElement("p");
    original.textContent = turn.original_text || turn.text;
    item.append(label, original);
    if (turn.corrected_text) {
      const corrected = document.createElement("p");
      corrected.textContent = `Corrected text: ${turn.corrected_text}`;
      item.append(corrected);
    }
    target.append(item);
  }
  target.scrollTop = target.scrollHeight;
}

function renderDraft() {
  const draft = state.draft;
  byId("revision-label").textContent = draft ? `Revision ${draft.revision}` : "Not saved";
  byId("save-edit").disabled = !draft || Boolean(stream);
  byId("confirm").disabled = !draft || Boolean(stream);
  byId("decline").disabled = !draft;
  byId("facts-list").replaceChildren();
  if (!draft) {
    byId("facts-list").innerHTML = '<p class="empty-state">Add a statement to begin a draft.</p>';
    byId("unknowns").value = "";
    return;
  }
  for (const fact of draft.facts) {
    const wrapper = document.createElement("label");
    wrapper.className = "fact-edit";
    const line = document.createElement("span");
    line.className = "fact-label";
    line.innerHTML = `<span>${fact.fact_id}</span><em>${fact.source === "employee_statement" ? "Employee statement" : "Consented device observation"}</em>`;
    const edit = document.createElement("textarea");
    edit.dataset.factId = fact.fact_id;
    edit.value = fact.text;
    wrapper.append(line, edit);
    byId("facts-list").append(wrapper);
  }
  byId("unknowns").value = draft.unknowns.join("\n");
}

async function sendText(text, synthetic = false, reportId = null, correctedText = null) {
  const language = byId("language").value;
  const result = await api("/api/drafts", {
    method: "POST",
    body: JSON.stringify({ text, language, incident_type: "other", report_id: reportId, corrected_text: correctedText, synthetic }),
  });
  state.draft = result.draft;
  for (const turn of state.draft.transcript) {
    if (!state.transcript.some((item) => item.turn_id === turn.turn_id)) state.transcript.push({ ...turn });
  }
  if (result.agent_reply) {
    state.transcript.push({ speaker: "agent", language, text: result.agent_reply, original_text: result.agent_reply });
    byId("agent-reply-text").textContent = result.agent_reply;
    byId("agent-reply").hidden = false;
    byId("agent-reply").querySelector("span").textContent = result.responder;
    byId("agent-reply").dataset.output = "live_model";
  } else {
    byId("agent-reply").hidden = true;
  }
  renderTranscript();
  renderDraft();
  byId("employee-ack").textContent = result.agent_reply ? "Live model response received. Draft remains unconfirmed." : "Statement saved to the draft. Gemini response unavailable.";
  return result.draft;
}

byId("message-form").addEventListener("submit", async (event) => {
  event.preventDefault();
  const text = byId("message").value.trim();
  if (!text) return;
  try {
    if (stream) await stopMicrophone();
    const draft = await sendText(text, false, state.draft?.report_id || null);
    byId("message").value = "";
    byId("message").focus();
    state.draft = draft;
  } catch (error) { byId("employee-ack").textContent = error.message; }
});

byId("language").addEventListener("change", () => {
  byId("message").dir = isRtl(byId("language").value) ? "rtl" : "auto";
  if (stream) {
    const previous = state.live;
    state.live = null;
    previous?.socket.close();
    clearPlayback();
    connectLive();
  }
});

byId("save-edit").addEventListener("click", async () => {
  if (!state.draft) return;
  const facts = [...document.querySelectorAll("[data-fact-id]")].map((input) => ({
    ...state.draft.facts.find((fact) => fact.fact_id === input.dataset.factId),
    text: input.value,
  }));
  try {
    state.draft = await api(`/api/drafts/${encodeURIComponent(state.draft.report_id)}`, {
      method: "PATCH",
      body: JSON.stringify({ facts, unknowns: byId("unknowns").value.split("\n").filter(Boolean) }),
    });
    renderDraft();
    byId("employee-ack").textContent = "Draft edit saved. Review and confirm again before ticket creation.";
  } catch (error) { byId("employee-ack").textContent = error.message; }
});

byId("confirm").addEventListener("click", async () => {
  if (!state.draft || !window.confirm("Create a synthetic ticket from this reviewed report?")) return;
  const keyName = `anuvach-confirm-${state.draft.report_id}-${state.draft.revision}`;
  const idempotencyKey = localStorage.getItem(keyName) || crypto.randomUUID();
  localStorage.setItem(keyName, idempotencyKey);
  try {
    const result = await api(`/api/drafts/${encodeURIComponent(state.draft.report_id)}/confirm`, {
      method: "POST",
      body: JSON.stringify({ confirmed: true, idempotency_key: idempotencyKey, revision: state.draft.revision }),
    });
    byId("employee-ack").textContent = `Storage acknowledged synthetic ticket ${result.ticket_id}.`;
    await refreshTickets();
  } catch (error) { byId("employee-ack").textContent = error.message; }
});

byId("decline").addEventListener("click", async () => {
  if (!state.draft) return;
  if (stream) await stopMicrophone();
  liveReportId = null;
  state.draft = null;
  renderDraft();
  byId("employee-ack").textContent = "Draft not confirmed. No ticket was created; the local draft remains stored.";
});

async function loadScenarios() {
  const scenarios = await api("/api/scenarios");
  for (const item of scenarios) {
    const option = document.createElement("option");
    option.value = item.id;
    option.textContent = item.label;
    byId("scenario").append(option);
  }
}

byId("replay").addEventListener("click", async () => {
  const id = byId("scenario").value;
  if (!id) return;
  try {
    const result = await api(`/api/scenarios/${id}`, { method: "POST", body: "{}" });
    await stopMicrophone();
    state.draft = result.draft;
    state.transcript = result.draft.transcript.map((turn) => ({ ...turn }));
    renderTranscript();
    renderDraft();
    byId("employee-ack").textContent = "Synthetic case loaded. It is not a real employee report.";
  } catch (error) { byId("employee-ack").textContent = error.message; }
});

byId("reset").addEventListener("click", async () => {
  if (!window.confirm("Reset all local synthetic tickets, proposals, drafts, and audit events?")) return;
  await stopMicrophone();
  await api("/api/reset", { method: "POST", body: "{}" });
  state.draft = null;
  liveReportId = null;
  state.tickets = [];
  state.selectedTicket = null;
  state.transcript = [];
  state.partialTurns = {};
  renderTranscript();
  renderDraft();
  byId("employee-ack").textContent = "Local synthetic test data reset.";
});

async function refreshTickets() {
  try {
    state.tickets = await api("/api/tickets");
    renderTickets();
  } catch (error) { byId("ticket-list").textContent = error.message; }
}

function renderTickets() {
  const list = byId("ticket-list");
  list.replaceChildren();
  if (!state.tickets.length) {
    list.innerHTML = '<p class="empty-state">No confirmed synthetic tickets yet.</p>';
    return;
  }
  for (const ticket of state.tickets) {
    const button = document.createElement("button");
    button.className = `ticket-row ${state.selectedTicket?.ticket_id === ticket.ticket_id ? "selected" : ""}`;
    const ticketId = document.createElement("strong");
    ticketId.textContent = ticket.ticket_id;
    const summary = document.createElement("span");
    summary.textContent = ticket.report.facts[0]?.text || "Confirmed report";
    const status = document.createElement("small");
    status.textContent = ticket.triage_status.toUpperCase();
    button.append(ticketId, summary, status);
    button.addEventListener("click", () => { state.selectedTicket = ticket; renderTickets(); renderTicketDetail(); });
    list.append(button);
  }
  if (state.selectedTicket) {
    state.selectedTicket = state.tickets.find((item) => item.ticket_id === state.selectedTicket.ticket_id) || null;
    renderTicketDetail();
  }
}

function renderTicketDetail() {
  const ticket = state.selectedTicket;
  byId("admin-facts").replaceChildren();
  byId("proposal-view").replaceChildren();
  byId("admin-decisions").hidden = true;
  byId("run-triage").disabled = !ticket;
  if (!ticket) { byId("ticket-title").textContent = "Select a ticket"; return; }
  byId("ticket-title").textContent = ticket.ticket_id;
  const taskId = ticket.triage_state?.task_id;
  byId("triage-status").textContent = `Triage ${ticket.triage_status}${taskId ? ` · A2A task ${taskId}` : ""}. Human review required. No company-policy grounding.`;
  for (const fact of ticket.report.facts) {
    const row = document.createElement("div");
    row.className = "evidence-fact";
    row.innerHTML = `<small>${fact.fact_id} · ${fact.source.replaceAll("_", " ")}</small>`;
    const text = document.createElement("p"); text.textContent = fact.text; row.append(text);
    byId("admin-facts").append(row);
  }
  const pending = ticket.triage_status === "pending";
  document.querySelector('[data-decision="accept"]').disabled = !ticket.triage;
  if (pending) {
    byId("triage-status").textContent += ` ${ticket.triage_state?.error || ""}`;
    byId("admin-decisions").hidden = false;
  }
  if (!ticket.triage) return;
  const proposal = ticket.triage;
  const section = document.createElement("section"); section.className = "proposal-section";
  const head = document.createElement("div"); head.className = "proposal-head";
  for (const label of [`${proposal.proposed_severity} severity`, `Team: ${proposal.proposed_team}`, `Type: ${proposal.incident_type}`, "Human review required"]) {
    const chip = document.createElement("span"); chip.className = "proposal-chip"; chip.textContent = label; head.append(chip);
  }
  section.append(head);
  for (const reason of proposal.reasons) {
    const row = document.createElement("p"); row.className = "proposal-reason"; row.textContent = reason.text;
    const refs = document.createElement("small"); refs.textContent = `Evidence: ${reason.fact_ids.join(", ")}`; row.append(refs); section.append(row);
  }
  const uncertainty = document.createElement("p"); uncertainty.className = "uncertainty";
  uncertainty.textContent = `Unknowns: ${proposal.unknowns.join(" · ") || "None listed"}`; section.append(uncertainty);
  const questions = document.createElement("p"); questions.className = "uncertainty";
  questions.textContent = `Suggested questions: ${proposal.recommended_next_questions.join(" · ") || "None"}`; section.append(questions);
  byId("proposal-view").append(section);
  byId("admin-decisions").hidden = false;
}

byId("refresh-tickets").addEventListener("click", refreshTickets);
byId("run-triage").addEventListener("click", async () => {
  if (!state.selectedTicket) return;
  byId("triage-status").textContent = "Sending confirmed structured report over A2A…";
  try {
    const result = await api(`/api/tickets/${encodeURIComponent(state.selectedTicket.ticket_id)}/triage`, { method: "POST", body: JSON.stringify({ retry: true }) });
    byId("triage-status").textContent = result.status === "completed" ? `A2A task completed${result.task_id ? ` · ${result.task_id}` : ""}.` : `Human review required. Ticket remains intact. ${result.error || ""}`;
    await refreshTickets();
  } catch (error) { byId("triage-status").textContent = error.message; }
});

document.querySelectorAll("[data-decision]").forEach((button) => button.addEventListener("click", async () => {
  if (!state.selectedTicket) return;
  const decision = button.dataset.decision;
  const details = decision === "edit" ? { proposed_team: "unknown", proposed_severity: "unassessed", note: "Edited in synthetic workbench." } : {};
  try {
    const result = await api(`/api/tickets/${encodeURIComponent(state.selectedTicket.ticket_id)}/decision`, { method: "POST", body: JSON.stringify({ decision, details }) });
    byId("decision-ack").textContent = `Simulated decision acknowledged: ${result.decision_id}.`;
  } catch (error) { byId("decision-ack").textContent = error.message; }
}));

async function refreshDiagnostics() {
  const target = byId("diagnostic-grid");
  try {
    const data = await api("/api/diagnostics");
    const items = [
      ["REPORTING CONNECTION", data.connections.gemini],
      ["REPORTING AGENT", data.agents.reporting],
      ["REPORTING TEXT MODEL", data.agents.reporting_text_model],
      ["LIVE MODEL", data.agents.reporting_model],
      ["TRIAGE AGENT", `${data.agents.triage} · ${data.agents.triage_provider}`],
      ["TRIAGE MODEL", data.agents.triage_model],
      ["A2A CARD", data.a2a_agent_card.available ? data.a2a_agent_card.name : data.a2a_agent_card.error || "unavailable"],
      ["A2A CARD URL", data.a2a_agent_card.url],
      ["A2A TASK ID", data.last_a2a.task_id || "not submitted"],
      ["CORRELATION ID", data.last_a2a.correlation_id || "not submitted"],
      ["A2A RESULT", data.last_a2a.status || "not submitted"],
      ["REPORTING LATENCY", data.latencies_ms.reporting_ms == null ? "not measured" : `${Math.round(data.latencies_ms.reporting_ms)} ms`],
      ["A2A LATENCY", data.latencies_ms.a2a_ms == null ? "not measured" : `${Math.round(data.latencies_ms.a2a_ms)} ms`],
      ["RAW AUDIO RETENTION", data.raw_audio_retention ? "enabled" : "disabled"],
      ["POLICY GROUNDING", data.policy_grounding],
      ["STAGE 1–2 API", data.stage12_adapter],
    ];
    target.replaceChildren();
    for (const [label, value] of items) {
      const tile = document.createElement("div"); tile.className = "diagnostic-item";
      const caption = document.createElement("span"); caption.textContent = label;
      const output = document.createElement("strong"); output.textContent = value;
      tile.append(caption, output); target.append(tile);
    }
    renderLog("tool-log", data.tool_calls.map((item) => ({ key: `${item.result?.responder ? `${item.result.responder} · ` : ""}${item.tool} · ${item.ok ? "ok" : "failed"}`, value: item.result })));
    renderLog("audit-log", data.audit_events.map((item) => ({ key: `${item.action} · ${item.at}`, value: item.data })));
    byId("error-log").textContent = data.errors.length ? data.errors.join("\n") : "No errors recorded.";
    byId("service-label").textContent = data.connections.a2a === "connected" ? "A2A peer connected" : "Local workbench · A2A pending";
    byId("mic-start").disabled = Boolean(stream) || data.connections.gemini !== "configured";
    if (data.connections.gemini !== "configured") byId("voice-state").textContent = "Live voice not configured";
  } catch (error) { target.textContent = error.message; }
}

function renderLog(targetId, rows) {
  const target = byId(targetId); target.replaceChildren();
  if (!rows.length) { target.textContent = "No events yet."; return; }
  for (const row of rows.slice().reverse()) {
    const line = document.createElement("div"); line.className = "log-row";
    const label = document.createElement("span"); label.textContent = row.key;
    const value = document.createElement("code"); value.textContent = JSON.stringify(row.value);
    line.append(label, value); target.append(line);
  }
}

byId("refresh-diagnostics").addEventListener("click", refreshDiagnostics);

let audioContext = null;
let stream = null;
let processor = null;
let source = null;
let playbackSources = new Set();
let playbackCursor = 0;
let reconnectTimer;
let reconnectAttempts = 0;
let liveReportId = null;
let liveSessionId = null;

function clearPlayback() {
  for (const player of playbackSources) {
    try { player.stop(); } catch {}
  }
  playbackSources.clear();
  playbackCursor = 0;
}

function connectLive() {
  if (!stream || state.live) return;
  const scheme = location.protocol === "https:" ? "wss:" : "ws:";
  const query = new URLSearchParams({
    session_id: liveSessionId, report_id: liveReportId, language: byId("language").value,
  });
  const socket = new WebSocket(`${scheme}//${location.host}/api/live?${query}`);
  const connection = { socket };
  state.live = connection;
  socket.onopen = () => socket.send(JSON.stringify({ type: "greet" }));
  socket.onmessage = (event) => {
    if (state.live !== connection) return;
    const message = JSON.parse(event.data);
    if (message.type === "state") {
      byId("voice-state").textContent = message.state;
      if (message.state === "interrupted") {
        clearPlayback();
        delete state.partialTurns.agent;
        renderTranscript();
        byId("interrupt-state").textContent = "Agent interrupted";
      } else if (message.state === "listening") {
        reconnectAttempts = 0;
        byId("interrupt-state").textContent = "Listening for interruption";
      }
    } else if (message.type === "error") {
      byId("employee-ack").textContent = message.message;
    } else if (message.type === "transcript") {
      const { role, language, text } = message;
      if (message.partial) {
        const earlier = state.partialTurns[role]?.original_text || "";
        state.partialTurns[role] = { speaker: role, language, original_text: earlier + text, partial: true };
      } else {
        delete state.partialTurns[role];
        state.transcript.push({ speaker: role, language, original_text: text, turn_id: message.turn_id });
        if (message.draft) {
          state.draft = message.draft;
          renderDraft();
        }
      }
      renderTranscript();
    } else if (message.type === "audio") {
      reconnectAttempts = 0;
      playPcm(message.data, message.mime_type);
    }
  };
  socket.onclose = (event) => {
    if (state.live !== connection) return;
    state.live = null;
    clearPlayback();
    state.partialTurns = {};
    renderTranscript();
    if (!stream) return;
    if (event.code !== 4401 && reconnectAttempts < 4) {
      const delay = 500 * 2 ** reconnectAttempts++;
      byId("voice-state").textContent = "Voice disconnected. Reconnecting…";
      reconnectTimer = setTimeout(connectLive, delay);
    } else {
      void stopMicrophone().then(() => { byId("voice-state").textContent = "Voice unavailable. Use text entry."; });
    }
  };
}

function toBase64(bytes) {
  let binary = "";
  for (let index = 0; index < bytes.length; index += 0x8000) binary += String.fromCharCode(...bytes.subarray(index, index + 0x8000));
  return btoa(binary);
}

function resampleTo16k(floatSamples, inputRate) {
  const ratio = inputRate / 16000;
  const length = Math.floor(floatSamples.length / ratio);
  const output = new Int16Array(length);
  for (let index = 0; index < length; index++) {
    const sample = floatSamples[Math.floor(index * ratio)] || 0;
    output[index] = Math.max(-1, Math.min(1, sample)) * 0x7fff;
  }
  return output;
}

async function startMicrophone() {
  try {
    stream = await navigator.mediaDevices.getUserMedia({ audio: { channelCount: 1, echoCancellation: true, noiseSuppression: true } });
    audioContext = new AudioContext();
    await audioContext.resume();
    source = audioContext.createMediaStreamSource(stream);
    processor = audioContext.createScriptProcessor(1024, 1, 1);
    const nextReportId = state.draft?.report_id || liveReportId || `R-${crypto.randomUUID()}`;
    if (nextReportId !== liveReportId) liveSessionId = crypto.randomUUID();
    liveReportId = nextReportId;
    reconnectAttempts = 0;
    connectLive();
    processor.onaudioprocess = (event) => {
      const socket = state.live?.socket;
      if (socket?.readyState !== WebSocket.OPEN || socket.bufferedAmount > 65536) return;
      const pcm = resampleTo16k(event.inputBuffer.getChannelData(0), audioContext.sampleRate);
      socket.send(JSON.stringify({ type: "audio", mime_type: "audio/pcm;rate=16000", data: toBase64(new Uint8Array(pcm.buffer)) }));
    };
    source.connect(processor);
    processor.connect(audioContext.destination);
    byId("mic-start").disabled = true;
    byId("mic-stop").disabled = false;
    byId("voice-state").textContent = "Microphone active";
    renderDraft();
  } catch (error) {
    await stopMicrophone();
    byId("employee-ack").textContent = `Microphone unavailable: ${error.message}`;
  }
}

async function stopMicrophone(finishTurn = false) {
  clearTimeout(reconnectTimer);
  const socket = state.live?.socket;
  const pending = finishTurn && socket?.readyState === WebSocket.OPEN
    ? waitForVoiceTurn(socket)
    : null;
  if (!pending) state.live = null;
  if (socket?.readyState === WebSocket.OPEN) socket.send(JSON.stringify({ type: finishTurn ? "finish" : "audio_end" }));
  processor?.disconnect();
  source?.disconnect();
  stream?.getTracks().forEach((track) => track.stop());
  stream = null;
  processor = null;
  source = null;
  if (pending) {
    byId("mic-stop").disabled = true;
    byId("voice-state").textContent = "Finishing voice turn…";
    await pending;
    state.live = null;
  }
  clearPlayback();
  if (audioContext && audioContext.state !== "closed") await audioContext.close();
  audioContext = null;
  socket?.close();
  state.partialTurns = {};
  renderTranscript();
  byId("mic-start").disabled = false;
  byId("mic-stop").disabled = true;
  byId("voice-state").textContent = "Microphone stopped";
  renderDraft();
}

function waitForVoiceTurn(socket) {
  return new Promise((resolve) => {
    const complete = () => {
      clearTimeout(timeout);
      socket.removeEventListener("message", onMessage);
      socket.removeEventListener("close", complete);
      resolve();
    };
    const onMessage = (event) => {
      if (JSON.parse(event.data).state === "closed_turn") {
        const remaining = Math.max(0, playbackCursor - (audioContext?.currentTime ?? 0));
        clearTimeout(timeout);
        timeout = setTimeout(complete, Math.min(4000, remaining * 1000 + 100));
      }
    };
    let timeout = setTimeout(complete, 15000);
    socket.addEventListener("message", onMessage);
    socket.addEventListener("close", complete);
  });
}

function playPcm(encoded, mimeType) {
  if (!audioContext || audioContext.state === "closed") return;
  const binary = atob(encoded);
  const sampleRate = Number(/rate=(\d+)/.exec(mimeType)?.[1] || 24000);
  const audio = audioContext.createBuffer(1, binary.length / 2, sampleRate);
  const channel = audio.getChannelData(0);
  for (let index = 0; index < channel.length; index++) {
    const sample = binary.charCodeAt(index * 2) | (binary.charCodeAt(index * 2 + 1) << 8);
    channel[index] = (sample >= 32768 ? sample - 65536 : sample) / 32768;
  }
  const player = audioContext.createBufferSource();
  player.buffer = audio;
  player.connect(audioContext.destination);
  const start = Math.max(playbackCursor, audioContext.currentTime);
  player.start(start);
  playbackCursor = start + audio.duration;
  playbackSources.add(player);
  player.onended = () => playbackSources.delete(player);
}

byId("mic-start").addEventListener("click", startMicrophone);
byId("mic-stop").addEventListener("click", () => stopMicrophone(true));

loadScenarios().catch(() => {});
refreshDiagnostics();