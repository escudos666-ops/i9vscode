export default function HomePage() {
  return (
    <main>
      <h1>VSCode Dash AI</h1>
      <p>Connector dashboard is running.</p>

      <div className="card">
        <h2>Test endpoints</h2>
        <p><a href="/api/status">/api/status</a></p>
        <p><a href="/api/db">/api/db</a></p>
        <p><a href="/api/vscode/workspace">/api/vscode/workspace</a></p>
        <p><a href="/api/shopify/orders">/api/shopify/orders</a></p>
        <p><a href="/api/outlook/messages">/api/outlook/messages</a></p>
      </div>
    </main>
  );
}