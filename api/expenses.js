// File: api/expenses.js
import { createClient } from "@supabase/supabase-js";

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  throw new Error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY environment variables");
}

// Create a server-side Supabase client using the SERVICE ROLE key (server-only)
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
  auth: { persistSession: false }
});

// Helper: get user from bearer token (returns user object or null)
async function getUserFromAuthHeader(authHeader) {
  if (!authHeader) return null;
  const match = authHeader.match(/^Bearer (.+)$/);
  if (!match) return null;
  const token = match[1];

  // Verify token and retrieve user
  const { data, error } = await supabase.auth.getUser(token);
  if (error || !data?.user) return null;
  return data.user;
}

export default async function handler(req, res) {
  try {
    const user = await getUserFromAuthHeader(req.headers.authorization);
    if (!user) {
      return res.status(401).json({ error: "Unauthorized — provide Authorization: Bearer <access_token>" });
    }
    const userId = user.id;

    if (req.method === "GET") {
      // Optionally accept ?limit= & ?offset= & ?q= filters
      const limit = parseInt(req.query.limit, 10) || 100;
      const offset = parseInt(req.query.offset, 10) || 0;

      const { data, error } = await supabase
        .from("transactions")
        .select(`id, amount, currency, type, merchant, note, happened_at, created_at, updated_at, account_id, category_id`)
        .eq("user_id", userId)
        .order("happened_at", { ascending: false })
        .range(offset, offset + limit - 1);

      if (error) return res.status(500).json({ error: error.message });
      return res.status(200).json(data);
    }

    if (req.method === "POST") {
      // Expect JSON body
      const {
        amount,
        currency = "USD",
        type = "expense",
        merchant = null,
        note = null,
        happened_at = null,
        account_id = null,
        category_id = null,
        is_recurring = false
      } = req.body || {};

      // Basic validation
      if (typeof amount !== "number" || isNaN(amount)) {
        return res.status(400).json({ error: "Invalid or missing 'amount' (must be number)" });
      }
      if (!["expense", "income", "transfer"].includes(type)) {
        return res.status(400).json({ error: "Invalid 'type' — must be 'expense', 'income' or 'transfer'" });
      }

      const insertRow = {
        user_id: userId,
        amount,
        currency,
        type,
        merchant,
        note,
        happened_at: happened_at || new Date().toISOString(),
        account_id,
        category_id,
        is_recurring
      };

      const { data, error } = await supabase
        .from("transactions")
        .insert([insertRow])
        .select()
        .single();

      if (error) return res.status(500).json({ error: error.message });

      return res.status(201).json(data);
    }

    return res.status(405).json({ error: "Method not allowed" });
  } catch (err) {
    console.error("API error:", err);
    return res.status(500).json({ error: "Server error" });
  }
}
