type Agent = {
  id: string;
  name: string;
  status: string;
  description: string;
};

export function AgentCard({ agent }: { agent: Agent }) {
  return (
    <div className="card">
      <h2>{agent.name}</h2>
      <p>Status: {agent.status}</p>
      <p>{agent.description}</p>
    </div>
  );
}
