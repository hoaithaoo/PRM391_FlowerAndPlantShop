import { createClient } from "@supabase/supabase-js";
import { env } from "../config/env";

// Supabase client with service_role key for backend operations and secure token verification
export const supabase = createClient(env.SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY, {
  auth: {
    autoRefreshToken: false,
    persistSession: false,
  },
});
