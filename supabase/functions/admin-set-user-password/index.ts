import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers":
        "authorization, x-client-info, apikey, content-type",
};

function jsonResponse(body: Record<string, unknown>, status = 200) {
    return new Response(JSON.stringify(body), {
        status,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
}

function generatePassword(length = 12) {
    const chars =
        "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#$%";
    let password = "";
    for (let i = 0; i < length; i += 1) {
        password += chars[Math.floor(Math.random() * chars.length)];
    }
    return password;
}

serve(async (req) => {
    if (req.method === "OPTIONS") {
        return new Response("ok", { headers: corsHeaders });
    }

    try {
        const payload = await req.json().catch(() => ({}));
        const userId = String(payload.user_id ?? "").trim();

        if (!userId) {
            return jsonResponse({ error: "Missing user_id" }, 400);
        }

        const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? Deno.env.get("PROJECT_URL");
        const serviceRoleKey = Deno.env.get("SERVICE_ROLE_KEY");

        if (!supabaseUrl || !serviceRoleKey) {
            return jsonResponse({ error: "Missing server configuration" }, 500);
        }

        const adminClient = createClient(supabaseUrl, serviceRoleKey, {
            auth: {
                autoRefreshToken: false,
                persistSession: false,
            },
        });

        const authHeader = req.headers.get("Authorization") ?? "";
        const token = authHeader.replace("Bearer ", "").trim();
        if (!token) {
            return jsonResponse({ error: "Missing authorization" }, 401);
        }

        const { data: userData, error: userError } = await adminClient.auth.getUser(token);
        if (userError || !userData?.user) {
            return jsonResponse({ error: "Unauthorized" }, 401);
        }

        const { data: profileData, error: profileError } = await adminClient
            .from("profiles")
            .select("role")
            .eq("id", userData.user.id)
            .maybeSingle();

        if (profileError || profileData?.role != "admin") {
            return jsonResponse({ error: "Forbidden" }, 403);
        }

        const tempPassword = generatePassword();

        // Attempt to update the user's password using the admin API
        // Note: using admin.updateUser may vary by supabase-js versions; this uses the admin namespace
        const { data: updatedUser, error: updateError } = await adminClient.auth.admin.updateUserById(userId, {
            password: tempPassword,
            email_confirm: true,
        } as any);

        if (updateError) {
            return jsonResponse({ error: updateError.message ?? 'Failed to update user' }, 400);
        }

        return jsonResponse({ user_id: userId, temp_password: tempPassword });
    } catch (error) {
        const message = error instanceof Error ? error.message : "Unknown error";
        return jsonResponse({ error: message }, 500);
    }
});
