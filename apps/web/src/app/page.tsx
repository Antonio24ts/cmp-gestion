import { createClient } from "@/lib/supabase/server";

export const dynamic = "force-dynamic";

export default async function HomePage() {
  const supabase = await createClient();

  const { data, error } = await supabase
    .from("app_health")
    .select("status, created_at")
    .eq("id", 1)
    .single();

  const connected = !error && data?.status === "ok";

  return (
    <main className="flex min-h-screen items-center justify-center bg-slate-100 p-6">
      <section className="w-full max-w-xl rounded-2xl bg-white p-8 shadow-sm">
        <p className="text-sm font-semibold uppercase tracking-wider text-slate-500">
          Restaurant Platform
        </p>

        <h1 className="mt-2 text-3xl font-bold text-slate-900">
          Comprobación del entorno
        </h1>

        <div className="mt-8 rounded-xl border border-slate-200 p-5">
          <div className="flex items-center gap-3">
            <span
              className={`h-3 w-3 rounded-full ${
                connected ? "bg-green-500" : "bg-red-500"
              }`}
            />

            <p className="font-semibold text-slate-900">
              {connected
                ? "Conexión con Supabase correcta"
                : "No se pudo conectar con Supabase"}
            </p>
          </div>

          {connected && data ? (
            <div className="mt-4 space-y-1 text-sm text-slate-600">
              <p>
                Estado:{" "}
                <span className="font-medium text-slate-900">
                  {data.status}
                </span>
              </p>

              <p>
                Registro creado:{" "}
                <span className="font-medium text-slate-900">
                  {new Date(data.created_at).toLocaleString("es-ES")}
                </span>
              </p>
            </div>
          ) : (
            <pre className="mt-4 overflow-auto rounded-lg bg-red-50 p-4 text-sm text-red-700">
              {error?.message ?? "Respuesta inesperada"}
            </pre>
          )}
        </div>
      </section>
    </main>
  );
}