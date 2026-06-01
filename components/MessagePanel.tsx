"use client";

import { useState } from "react";

export function MessagePanel() {
  const [message, setMessage] = useState("");
  const [reply, setReply] = useState("");

  async function sendMessage() {
    const response = await fetch("/api/chat", {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({ message })
    });

    const data = await response.json();
    setReply(data.reply);
  }

  return (
    <div className="panel">
      <h2>Ask local AI</h2>

      <textarea
        value={message}
        onChange={(event) => setMessage(event.target.value)}
        placeholder="Ask something..."
      />

      <br />

      <button onClick={sendMessage}>Send</button>

      {reply && <pre>{reply}</pre>}
    </div>
  );
}
