import { createClient } from "@supabase/supabase-js";
import { env, supabaseApiKey } from "../config/env";

// This client only verifies user access tokens. A publishable key is sufficient;
// create a separate server-only client if a future feature needs elevated access.
export const supabase = createClient(env.SUPABASE_URL, supabaseApiKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false,
  },
});
