import { config } from "dotenv";
import { readFileSync } from "fs";
import { Pool } from "pg";

config({ path: ".env.local" });

async function main() {
	const pool = new Pool({ connectionString: process.env.DATABASE_URL });
	await pool.query(readFileSync("db/schema.sql", "utf8"));
	await pool.end();
	console.log("Schema applied");
}

main().catch((e) => { console.error(e); process.exit(1); })

