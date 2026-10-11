import { pool } from "@/lib/db"

export async function GET() {
	try {
		const r = await pool.query("SELECT to_regclasss('public.settlemets') AS t");
		return Response.json({ ok: true, schema: r.rows[0].t != null });
	} catch {
		return Response.json({ ok: false }, { status: 500 });
	}
}

