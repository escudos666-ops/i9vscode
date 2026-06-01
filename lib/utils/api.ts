export function json(data: unknown, status = 200) {
  return Response.json(data, { status });
}

export function missingConfig(name: string) {
  return {
    ok: false,
    error: `Missing config: ${name}. Add it to .env.local and restart npm run dev.`
  };
}
