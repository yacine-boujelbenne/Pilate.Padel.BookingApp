// @ts-nocheck

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient, type SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

type JsonObject = Record<string, unknown>;

type NotificationEventRecord = {
    id: string;
    event_type: string;
    audience_type: "users" | "all" | "roles";
    recipient_user_ids: string[];
    recipient_roles: string[];
    push_provider: "fcm" | "expo" | "all";
    title: string;
    body: string;
    data: JsonObject;
    source_table: string | null;
    source_record_id: string | null;
    status: string;
    scheduled_at: string | null;
    processed_at: string | null;
    last_error: string | null;
};

type DeviceRecord = {
    id: string;
    user_id: string;
    device_token: string;
    platform: string;
    push_provider: "fcm" | "expo";
};

type FollowNotificationRequest = {
    event_type: "coach_session_assigned" | "session_updated" | "session_spot_opened" | "session_cancelled";
    session_id?: string;
    coach_id?: string;
    booking_id?: string;
    title?: string;
    body?: string;
    data?: JsonObject;
};

type AuthContext = {
    mode: "webhook" | "authenticated";
    userId?: string;
    role?: string;
};

type DeliveryResult = {
    status: "sent" | "failed" | "invalid_token";
    providerMessageId?: string;
    errorCode?: string;
    errorMessage?: string;
};

const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-webhook-secret, x-notification-secret",
};

const JSON_HEADERS = { "Content-Type": "application/json" };

function jsonResponse(body: JsonObject, status = 200) {
    return new Response(JSON.stringify(body), {
        status,
        headers: { ...corsHeaders, ...JSON_HEADERS },
    });
}

function toStringArray(value: unknown): string[] {
    if (!Array.isArray(value)) {
        return [];
    }

    return value
        .map((item) => String(item ?? "").trim())
        .filter((item) => item.length > 0);
}

function toJsonObject(value: unknown): JsonObject {
    if (value && typeof value === "object" && !Array.isArray(value)) {
        return value as JsonObject;
    }

    return {};
}

function escapeHtml(value: string): string {
    return value
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/\"/g, "&quot;")
        .replace(/'/g, "&#39;");
}

function normalizeNotificationEvent(input: unknown): NotificationEventRecord {
    const root = toJsonObject(input);
    const record = toJsonObject(root.record ?? root);

    const id = String(record.id ?? root.id ?? "").trim();
    const title = String(record.title ?? root.title ?? "").trim();
    const body = String(record.body ?? root.body ?? "").trim();
    const eventType = String(record.event_type ?? root.event_type ?? "general").trim() || "general";
    const audienceType = String(record.audience_type ?? root.audience_type ?? "users") as NotificationEventRecord["audience_type"];
    const pushProvider = String(record.push_provider ?? root.push_provider ?? "fcm") as NotificationEventRecord["push_provider"];

    return {
        id,
        event_type: eventType,
        audience_type: audienceType === "all" || audienceType === "roles" ? audienceType : "users",
        recipient_user_ids: toStringArray(record.recipient_user_ids ?? root.recipient_user_ids),
        recipient_roles: toStringArray(record.recipient_roles ?? root.recipient_roles),
        push_provider: pushProvider === "expo" || pushProvider === "all" ? pushProvider : "fcm",
        title,
        body,
        data: toJsonObject(record.data ?? root.data),
        source_table: String(record.source_table ?? root.source_table ?? "").trim() || null,
        source_record_id: String(record.source_record_id ?? root.source_record_id ?? "").trim() || null,
        status: String(record.status ?? root.status ?? "pending").trim(),
        scheduled_at: String(record.scheduled_at ?? root.scheduled_at ?? "").trim() || null,
        processed_at: String(record.processed_at ?? root.processed_at ?? "").trim() || null,
        last_error: String(record.last_error ?? root.last_error ?? "").trim() || null,
    };
}

function isFollowNotificationRequest(input: unknown): input is FollowNotificationRequest {
    const root = toJsonObject(input);
    const eventType = String(root.event_type ?? "").trim();
    return eventType === "coach_session_assigned" || eventType === "session_updated" || eventType === "session_spot_opened" || eventType === "session_cancelled";
}

function normalizeFollowNotificationRequest(input: unknown): FollowNotificationRequest {
    const root = toJsonObject(input);
    const eventType = String(root.event_type ?? "").trim();

    if (eventType !== "coach_session_assigned" && eventType !== "session_updated" && eventType !== "session_spot_opened" && eventType !== "session_cancelled") {
        throw new Error("Unsupported follow notification event");
    }

    return {
        event_type: eventType,
        session_id: String(root.session_id ?? "").trim() || undefined,
        coach_id: String(root.coach_id ?? "").trim() || undefined,
        booking_id: String(root.booking_id ?? "").trim() || undefined,
        title: String(root.title ?? "").trim() || undefined,
        body: String(root.body ?? "").trim() || undefined,
        data: toJsonObject(root.data),
    };
}

function normalizeHex(bytes: Uint8Array): string {
    return Array.from(bytes)
        .map((byte) => byte.toString(16).padStart(2, "0"))
        .join("");
}

function base64UrlEncode(value: string | Uint8Array): string {
    const bytes = typeof value === "string" ? new TextEncoder().encode(value) : value;
    let binary = "";
    for (const byte of bytes) {
        binary += String.fromCharCode(byte);
    }
    return btoa(binary)
        .replace(/=/g, "")
        .replace(/\+/g, "-")
        .replace(/\//g, "_");
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
    const body = pem
        .replace(/-----BEGIN PRIVATE KEY-----/g, "")
        .replace(/-----END PRIVATE KEY-----/g, "")
        .replace(/\s+/g, "");
    const bytes = Uint8Array.from(atob(body), (char) => char.charCodeAt(0));
    return bytes.buffer;
}

function getSupabaseUrl(): string {
    return Deno.env.get("SUPABASE_URL") ?? Deno.env.get("PROJECT_URL") ?? "";
}

function getServiceRoleKey(): string {
    return Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? Deno.env.get("SERVICE_ROLE_KEY") ?? "";
}

function getWebhookSecret(): string {
    return Deno.env.get("WEBHOOK_SECRET") ?? "";
}

async function createAdminClient(): Promise<SupabaseClient> {
    const supabaseUrl = getSupabaseUrl();
    const serviceRoleKey = getServiceRoleKey();

    if (!supabaseUrl || !serviceRoleKey) {
        throw new Error("Missing Supabase server configuration");
    }

    return createClient(supabaseUrl, serviceRoleKey, {
        auth: {
            autoRefreshToken: false,
            persistSession: false,
        },
    });
}

async function authorizeRequest(req: Request, adminClient: SupabaseClient): Promise<AuthContext> {
    const webhookSecret = getWebhookSecret();
    const providedSecret = req.headers.get("x-webhook-secret") ?? req.headers.get("x-notification-secret") ?? "";

    if (webhookSecret && providedSecret === webhookSecret) {
        return { mode: "webhook" };
    }

    const authHeader = req.headers.get("Authorization") ?? req.headers.get("authorization") ?? "";
    const bearerToken = authHeader.toLowerCase().startsWith("bearer ") ? authHeader.slice(7).trim() : "";

    if (!bearerToken) {
        throw new Error("Unauthorized");
    }

    const { data: userData, error: userError } = await adminClient.auth.getUser(bearerToken);
    if (userError || !userData?.user) {
        throw new Error("Unauthorized");
    }

    const { data: profile, error: profileError } = await adminClient
        .from("profiles")
        .select("role")
        .eq("id", userData.user.id)
        .maybeSingle();

    if (profileError || !profile?.role) {
        throw new Error("Forbidden");
    }

    return { mode: "authenticated", userId: userData.user.id, role: String(profile.role) };
}

async function resolveEvent(adminClient: SupabaseClient, payload: NotificationEventRecord, userId?: string): Promise<NotificationEventRecord> {
    if (payload.id) {
        const { data, error } = await adminClient
            .from("notification_events")
            .select("*")
            .eq("id", payload.id)
            .maybeSingle();

        if (!error && data) {
            return normalizeNotificationEvent(data);
        }
    }

    const { data, error } = await adminClient
        .from("notification_events")
        .insert({
            event_type: payload.event_type,
            audience_type: payload.audience_type,
            recipient_user_ids: payload.recipient_user_ids,
            recipient_roles: payload.recipient_roles,
            push_provider: payload.push_provider,
            title: payload.title,
            body: payload.body,
            data: payload.data,
            source_table: payload.source_table,
            source_record_id: payload.source_record_id,
            scheduled_at: payload.scheduled_at,
            created_by: userId ?? null,
        })
        .select("*")
        .single();

    if (error || !data) {
        throw new Error(error?.message ?? "Unable to create notification event");
    }

    return normalizeNotificationEvent(data);
}

async function lockNotificationEvent(adminClient: SupabaseClient, eventId: string): Promise<NotificationEventRecord | null> {
    const { data, error } = await adminClient
        .from("notification_events")
        .update({
            status: "processing",
            updated_at: new Date().toISOString(),
        })
        .eq("id", eventId)
        .eq("status", "pending")
        .select("*")
        .maybeSingle();

    if (error || !data) {
        return null;
    }

    return normalizeNotificationEvent(data);
}

async function resolveUserEmails(adminClient: SupabaseClient, userIds: string[]): Promise<Map<string, string>> {
    if (userIds.length === 0) {
        return new Map();
    }

    const result = new Map<string, string>();
    for (const userId of userIds) {
        try {
            const { data } = await adminClient.auth.admin.getUserById(userId);
            const email = data?.user?.email;
            if (email) {
                result.set(userId, email);
            }
        } catch (_error) {
            // Best effort.
        }
    }

    return result;
}

async function resolveEmailEnabledRecipients(adminClient: SupabaseClient, userIds: string[]): Promise<string[]> {
    if (userIds.length === 0) {
        return [];
    }

    const { data, error } = await adminClient
        .from("user_settings")
        .select("user_id, email_enabled")
        .in("user_id", userIds);

    if (error) {
        const message = String(error.message ?? "").toLowerCase();
        const missingUserSettings = message.includes("user_settings")
            && (message.includes("pgrst205") || message.includes("does not exist") || message.includes("schema cache"));
        if (missingUserSettings) {
            return userIds;
        }
        throw new Error(error.message);
    }

    const allowed = new Set(userIds);
    for (const row of data ?? []) {
        if (row.email_enabled === false) {
            allowed.delete(String(row.user_id));
        }
    }

    return Array.from(allowed);
}

function formatSessionDate(value: unknown): string {
    const valueString = String(value ?? "").trim();
    if (!valueString) {
        return "";
    }

    const parsed = new Date(valueString);
    if (Number.isNaN(parsed.getTime())) {
        return valueString;
    }

    return new Intl.DateTimeFormat("en", {
        dateStyle: "medium",
        timeStyle: "short",
    }).format(parsed);
}

async function buildFollowNotificationEvent(
    adminClient: SupabaseClient,
    request: FollowNotificationRequest,
    auth: AuthContext,
): Promise<NotificationEventRecord | null> {
    if (request.event_type === "coach_session_assigned") {
        if (!request.session_id || !request.coach_id) {
            throw new Error("Missing session or coach id");
        }

        if (auth.role !== "admin" && auth.role !== "coach") {
            throw new Error("Forbidden");
        }

        const [{ data: coachRow, error: coachError }, { data: sessionRow, error: sessionError }, { data: recipientRows, error: recipientError }] = await Promise.all([
            adminClient.from("profiles").select("first_name, last_name").eq("id", request.coach_id).maybeSingle(),
            adminClient.from("sessions").select("title, start_at, end_at, coach_id, studios(name)").eq("id", request.session_id).maybeSingle(),
            adminClient.from("coach_follows").select("member_id").eq("coach_id", request.coach_id),
        ]);

        if (coachError || sessionError || recipientError) {
            throw new Error(coachError?.message ?? sessionError?.message ?? recipientError?.message ?? "Unable to resolve follow recipients");
        }

        const recipientIds = Array.from(new Set((recipientRows ?? []).map((row) => String((row as JsonObject).member_id ?? "")).filter((id) => id.length > 0)));
        if (recipientIds.length === 0) {
            return null;
        }

        const coach = (coachRow ?? {}) as JsonObject;
        const session = (sessionRow ?? {}) as JsonObject;
        const studio = (session.studios ?? {}) as JsonObject;
        const coachName = `${String(coach.first_name ?? "")} ${String(coach.last_name ?? "")}`.trim() || "your followed coach";
        const sessionTitle = String(session.title ?? "Session");
        const studioName = String(studio.name ?? "Studio");

        return normalizeNotificationEvent({
            event_type: request.event_type,
            audience_type: "users",
            recipient_user_ids: recipientIds,
            recipient_roles: [],
            push_provider: "all",
            title: request.title ?? "New session from a followed coach",
            body:
                request.body ??
                `${sessionTitle} has been assigned to ${coachName} at ${studioName}${session.start_at ? ` · ${formatSessionDate(session.start_at)}` : ""}.`,
            data: {
                ...(request.data ?? {}),
                coach_id: request.coach_id,
                session_id: request.session_id,
                coach_name: coachName,
                session_title: sessionTitle,
                studio_name: studioName,
            },
            source_table: "sessions",
            source_record_id: request.session_id,
            status: "pending",
        });
    }

    if (request.event_type === "session_cancelled") {
        if (!request.session_id) {
            throw new Error("Missing session id");
        }

        if (auth.role !== "admin" && auth.role !== "coach") {
            throw new Error("Forbidden");
        }

        const [{ data: sessionRow, error: sessionError }, { data: sessionFollowerRows, error: sessionFollowerError }] = await Promise.all([
            adminClient
                .from("sessions")
                .select("title, start_at, end_at, coach_id, studios(name), profiles!coach_id(first_name, last_name)")
                .eq("id", request.session_id)
                .maybeSingle(),
            adminClient.from("session_follows").select("member_id").eq("session_id", request.session_id),
        ]);

        if (sessionError || sessionFollowerError) {
            throw new Error(sessionError?.message ?? sessionFollowerError?.message ?? "Unable to resolve follow recipients");
        }

        const session = (sessionRow ?? {}) as JsonObject;
        const coachId = String(session.coach_id ?? request.coach_id ?? "").trim();
        const { data: coachFollowerRows, error: coachFollowerError } = coachId
            ? await adminClient.from("coach_follows").select("member_id").eq("coach_id", coachId)
            : { data: [], error: null };

        if (coachFollowerError) {
            throw new Error(coachFollowerError.message);
        }

        const recipientIds = Array.from(new Set([
            ...((sessionFollowerRows ?? []).map((row) => String((row as JsonObject).member_id ?? "")).filter((id) => id.length > 0)),
            ...((coachFollowerRows ?? []).map((row) => String((row as JsonObject).member_id ?? "")).filter((id) => id.length > 0)),
        ]));

        if (recipientIds.length === 0) {
            return null;
        }

        const coach = (session.profiles ?? {}) as JsonObject;
        const studio = (session.studios ?? {}) as JsonObject;
        const coachName = `${String(coach.first_name ?? "")} ${String(coach.last_name ?? "")}`.trim() || "your coach";
        const sessionTitle = String(session.title ?? "Session");
        const studioName = String(studio.name ?? "Studio");

        return normalizeNotificationEvent({
            event_type: request.event_type,
            audience_type: "users",
            recipient_user_ids: recipientIds,
            recipient_roles: [],
            push_provider: "all",
            title: request.title ?? "Session cancelled",
            body:
                request.body ??
                `${sessionTitle} with ${coachName}${studioName ? ` at ${studioName}` : ""} has been cancelled.`,
            data: {
                ...(request.data ?? {}),
                session_id: request.session_id,
                coach_id: coachId,
                coach_name: coachName,
                session_title: sessionTitle,
                studio_name: studioName,
                status: "cancelled",
            },
            source_table: "sessions",
            source_record_id: request.session_id,
            status: "pending",
        });
    }

    if (request.event_type === "session_updated" || request.event_type === "session_spot_opened") {
        if (!request.session_id) {
            throw new Error("Missing session id");
        }

        if (request.event_type === "session_updated" && auth.role !== "admin" && auth.role !== "coach") {
            throw new Error("Forbidden");
        }

        if (request.event_type === "session_spot_opened" && auth.role !== "admin" && auth.role !== "coach") {
            if (!request.booking_id || !auth.userId) {
                throw new Error("Forbidden");
            }

            const { data: bookingRow, error: bookingError } = await adminClient
                .from("bookings")
                .select("id, member_id, session_id, status")
                .eq("id", request.booking_id)
                .maybeSingle();

            if (bookingError || !bookingRow || String((bookingRow as JsonObject).member_id ?? "") !== auth.userId) {
                throw new Error("Forbidden");
            }
        }

        const [{ data: sessionRow, error: sessionError }, { data: recipientRows, error: recipientError }, { data: waitlistRows, error: waitlistError }] = await Promise.all([
            adminClient
                .from("sessions")
                .select("title, start_at, end_at, max_participants, booked_count, coach_id, studios(name), profiles!coach_id(first_name, last_name)")
                .eq("id", request.session_id)
                .maybeSingle(),
            adminClient.from("session_follows").select("member_id").eq("session_id", request.session_id),
            request.event_type === "session_spot_opened"
                ? adminClient.from("waitlists").select("member_id").eq("session_id", request.session_id)
                : Promise.resolve({ data: [], error: null }),
        ]);

        if (sessionError || recipientError || waitlistError) {
            throw new Error(sessionError?.message ?? recipientError?.message ?? waitlistError?.message ?? "Unable to resolve follow recipients");
        }

        const recipientIds = Array.from(new Set([
            ...(recipientRows ?? []).map((row) => String((row as JsonObject).member_id ?? "")).filter((id) => id.length > 0),
            ...(waitlistRows ?? []).map((row) => String((row as JsonObject).member_id ?? "")).filter((id) => id.length > 0),
        ]));
        if (recipientIds.length === 0) {
            return null;
        }

        const session = (sessionRow ?? {}) as JsonObject;
        const coach = (session.profiles ?? {}) as JsonObject;
        const studio = (session.studios ?? {}) as JsonObject;
        const coachName = `${String(coach.first_name ?? "")} ${String(coach.last_name ?? "")}`.trim() || "your coach";
        const sessionTitle = String(session.title ?? "Session");
        const startAt = formatSessionDate(session.start_at);
        const isSpotOpenEvent = request.event_type === "session_spot_opened";

        return normalizeNotificationEvent({
            event_type: request.event_type,
            audience_type: "users",
            recipient_user_ids: recipientIds,
            recipient_roles: [],
            push_provider: "all",
            title: request.title ?? (isSpotOpenEvent ? "A spot opened up" : "Your followed session changed"),
            body:
                request.body ??
                (isSpotOpenEvent
                    ? `${sessionTitle}${startAt ? ` on ${startAt}` : ""} now has an open spot${coachName ? ` with ${coachName}` : ""}.`
                    : `${sessionTitle}${startAt ? ` on ${startAt}` : ""} has been updated${String(studio.name ?? "").trim() ? ` at ${studio.name}` : ""}.`),
            data: {
                ...(request.data ?? {}),
                session_id: request.session_id,
                booking_id: request.booking_id,
                session_title: sessionTitle,
                coach_name: coachName,
                studio_name: String(studio.name ?? "Studio"),
                booked_count: session.booked_count ?? null,
                max_participants: session.max_participants ?? null,
            },
            source_table: "sessions",
            source_record_id: request.session_id,
            status: "pending",
        });
    }

    return null;
}

async function resolveRecipientUserIds(adminClient: SupabaseClient, event: NotificationEventRecord): Promise<string[]> {
    const explicitRecipients = Array.from(new Set(event.recipient_user_ids.filter(Boolean)));
    if (explicitRecipients.length > 0) {
        const { data, error } = await adminClient
            .from("profiles")
            .select("id")
            .in("id", explicitRecipients)
            .eq("is_blocked", false);

        if (error || !data) {
            throw new Error(error?.message ?? "Unable to resolve recipients");
        }

        return data.map((row) => String(row.id)).filter((id) => id.length > 0);
    }

    let query = adminClient.from("profiles").select("id").eq("is_blocked", false);

    if (event.audience_type === "roles" && event.recipient_roles.length > 0) {
        query = query.in("role", event.recipient_roles);
    }

    if (event.audience_type === "all") {
        if (event.recipient_roles.length > 0) {
            query = query.in("role", event.recipient_roles);
        }
    }

    const { data, error } = await query;
    if (error || !data) {
        throw new Error(error?.message ?? "Unable to resolve recipients");
    }

    return data.map((row) => String(row.id)).filter((id) => id.length > 0);
}

async function resolvePushEnabledRecipients(adminClient: SupabaseClient, userIds: string[]): Promise<Set<string>> {
    if (userIds.length === 0) {
        return new Set<string>();
    }

    const { data, error } = await adminClient
        .from("user_settings")
        .select("user_id, push_enabled")
        .in("user_id", userIds);

    if (error) {
        const message = String(error.message ?? "").toLowerCase();
        const missingUserSettings = message.includes("user_settings")
            && (message.includes("pgrst205") || message.includes("does not exist") || message.includes("schema cache"));
        if (missingUserSettings) {
            return new Set(userIds);
        }
        throw new Error(error.message);
    }

    const allowed = new Set(userIds);
    for (const row of data ?? []) {
        if (row.push_enabled === false) {
            allowed.delete(String(row.user_id));
        }
    }

    return allowed;
}

async function upsertInAppNotifications(adminClient: SupabaseClient, event: NotificationEventRecord, recipientUserIds: string[]): Promise<number> {
    if (recipientUserIds.length === 0) {
        return 0;
    }

    const rows = recipientUserIds.map((recipientUserId) => ({
        event_id: event.id,
        member_id: recipientUserId,
        session_id: event.source_table === "sessions" ? event.source_record_id : null,
        title: event.title,
        body: event.body,
        is_read: false,
        event_type: event.event_type,
        channel: "in_app",
        data: event.data,
        delivered_at: new Date().toISOString(),
    }));

    const { error } = await adminClient.from("notifications").upsert(rows, {
        onConflict: "event_id,member_id",
        ignoreDuplicates: true,
    });

    if (error) {
        throw new Error(error.message);
    }

    return rows.length;
}

async function fetchDevices(adminClient: SupabaseClient, userIds: string[], eventPushProvider: NotificationEventRecord["push_provider"]): Promise<DeviceRecord[]> {
    if (userIds.length === 0) {
        return [];
    }

    const { data, error } = await adminClient
        .from("user_devices")
        .select("id, user_id, device_token, platform, push_provider")
        .eq("is_active", true)
        .in("user_id", userIds);

    if (error) {
        throw new Error(error.message);
    }

    const devices = (data ?? []).map((row) => ({
        id: String(row.id),
        user_id: String(row.user_id),
        device_token: String(row.device_token),
        platform: String(row.platform),
        push_provider: String(row.push_provider) as DeviceRecord["push_provider"],
    }));

    return devices.filter((device) => {
        if (eventPushProvider === "all") {
            return true;
        }

        return device.push_provider === eventPushProvider;
    });
}

function parseGoogleServiceAccount(): JsonObject | null {
    const raw = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON");
    if (!raw) {
        return null;
    }

    try {
        return JSON.parse(raw) as JsonObject;
    } catch {
        return null;
    }
}

const googleTokenCache = {
    accessToken: "",
    expiresAt: 0,
};

async function getGoogleAccessToken(): Promise<string> {
    if (googleTokenCache.accessToken && Date.now() < googleTokenCache.expiresAt - 60_000) {
        return googleTokenCache.accessToken;
    }

    const serviceAccount = parseGoogleServiceAccount();
    if (!serviceAccount) {
        throw new Error("Missing FCM_SERVICE_ACCOUNT_JSON");
    }

    const privateKey = String(serviceAccount.private_key ?? "").replace(/\\n/g, "\n");
    const clientEmail = String(serviceAccount.client_email ?? "");
    const tokenUri = String(serviceAccount.token_uri ?? "https://oauth2.googleapis.com/token");

    if (!privateKey || !clientEmail) {
        throw new Error("Invalid Google service account configuration");
    }

    const header = base64UrlEncode(JSON.stringify({ alg: "RS256", typ: "JWT" }));
    const now = Math.floor(Date.now() / 1000);
    const claim = base64UrlEncode(JSON.stringify({
        iss: clientEmail,
        scope: "https://www.googleapis.com/auth/firebase.messaging",
        aud: tokenUri,
        iat: now,
        exp: now + 3600,
    }));
    const signingInput = `${header}.${claim}`;

    const key = await crypto.subtle.importKey(
        "pkcs8",
        pemToArrayBuffer(privateKey),
        { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
        false,
        ["sign"],
    );

    const signature = await crypto.subtle.sign(
        "RSASSA-PKCS1-v1_5",
        key,
        new TextEncoder().encode(signingInput),
    );

    const jwt = `${signingInput}.${base64UrlEncode(new Uint8Array(signature))}`;
    const tokenResponse = await fetch(tokenUri, {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: new URLSearchParams({
            grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
            assertion: jwt,
        }),
    });

    if (!tokenResponse.ok) {
        throw new Error(`Unable to mint Google access token: ${tokenResponse.status}`);
    }

    const tokenJson = await tokenResponse.json() as { access_token?: string; expires_in?: number };
    if (!tokenJson.access_token) {
        throw new Error("Google access token not returned");
    }

    googleTokenCache.accessToken = tokenJson.access_token;
    googleTokenCache.expiresAt = Date.now() + (Number(tokenJson.expires_in ?? 3600) * 1000);
    return googleTokenCache.accessToken;
}

function getFcmProjectId(): string {
    const serviceAccount = parseGoogleServiceAccount();
    return Deno.env.get("FCM_PROJECT_ID") ?? String(serviceAccount?.project_id ?? "");
}

function isInvalidTokenError(provider: "fcm" | "expo", status: number, errorCode: string, errorMessage: string): boolean {
    const normalized = `${errorCode} ${errorMessage}`.toLowerCase();
    if (provider === "fcm") {
        return normalized.includes("not-registered") || normalized.includes("registration-token-not-registered") || normalized.includes("invalid-argument");
    }

    return status === 400 || normalized.includes("devicenotregistered") || normalized.includes("push token");
}

async function sendFcmPush(device: DeviceRecord, event: NotificationEventRecord): Promise<DeliveryResult> {
    const projectId = getFcmProjectId();
    if (!projectId) {
        return {
            status: "failed",
            errorCode: "missing_project_id",
            errorMessage: "Missing FCM project id",
        };
    }

    const accessToken = await getGoogleAccessToken();
    const response = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
        method: "POST",
        headers: {
            "Authorization": `Bearer ${accessToken}`,
            "Content-Type": "application/json",
        },
        body: JSON.stringify({
            message: {
                token: device.device_token,
                notification: {
                    title: event.title,
                    body: event.body,
                },
                data: Object.fromEntries(
                    Object.entries(event.data).map(([key, value]) => [key, String(value)]),
                ),
                android: {
                    priority: "HIGH",
                    notification: {
                        channel_id: "push_notifications",
                    },
                },
                apns: {
                    payload: {
                        aps: {
                            sound: "default",
                        },
                    },
                },
            },
        }),
    });

    const responseBody = await response.json().catch(() => ({} as JsonObject));
    if (!response.ok) {
        const message = String((responseBody as JsonObject).error?.message ?? (responseBody as JsonObject).message ?? response.statusText);
        const code = String((responseBody as JsonObject).error?.status ?? response.status);
        return {
            status: isInvalidTokenError("fcm", response.status, code, message) ? "invalid_token" : "failed",
            errorCode: code,
            errorMessage: message,
        };
    }

    return {
        status: "sent",
        providerMessageId: String((responseBody as JsonObject).name ?? ""),
    };
}

async function sendExpoPush(device: DeviceRecord, event: NotificationEventRecord): Promise<DeliveryResult> {
    const response = await fetch("https://exp.host/--/api/v2/push/send", {
        method: "POST",
        headers: {
            "Accept": "application/json",
            "Content-Type": "application/json",
        },
        body: JSON.stringify({
            to: device.device_token,
            title: event.title,
            body: event.body,
            sound: "default",
            data: event.data,
            priority: "high",
        }),
    });

    const responseBody = await response.json().catch(() => ({} as JsonObject));
    if (!response.ok) {
        const message = String((responseBody as JsonObject).errors?.[0]?.message ?? (responseBody as JsonObject).message ?? response.statusText);
        const code = String((responseBody as JsonObject).errors?.[0]?.code ?? response.status);
        return {
            status: isInvalidTokenError("expo", response.status, code, message) ? "invalid_token" : "failed",
            errorCode: code,
            errorMessage: message,
        };
    }

    const data = responseBody as JsonObject;
    const expoTicket = Array.isArray(data.data) ? data.data[0] : data.data;
    const ticketId = String(expoTicket?.id ?? "");
    return {
        status: "sent",
        providerMessageId: ticketId || undefined,
    };
}

async function sendPushToDevice(device: DeviceRecord, event: NotificationEventRecord): Promise<DeliveryResult> {
    if (device.push_provider === "expo") {
        return await sendExpoPush(device, event);
    }

    return await sendFcmPush(device, event);
}

async function sendEmailSendGrid(apiKey: string, from: string, to: string, subject: string, content: string) {
    try {
        await fetch('https://api.sendgrid.com/v3/mail/send', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${apiKey}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                personalizations: [
                    { to: [{ email: to }] }
                ],
                from: { email: from },
                subject,
                content: [
                    { type: 'text/plain', value: content },
                    { type: 'text/html', value: `<p>${content}</p>` }
                ]
            })
        });
    } catch (_e) {
        // swallow errors; email is best-effort here
    }
}

async function sendMailtrapBulk(
    apiToken: string,
    fromEmail: string,
    fromName: string,
    recipientEmails: string[],
    subject: string,
    content: string,
) {
    if (!apiToken || !fromEmail || recipientEmails.length === 0) {
        return;
    }

    try {
        await fetch('https://bulk.api.mailtrap.io/api/send', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${apiToken}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                from: {
                    email: fromEmail,
                    name: fromName,
                },
                to: recipientEmails.map((email) => ({ email })),
                subject,
                text: content,
                html: `<p>${escapeHtml(content).replace(/\n/g, '<br />')}</p>`,
            }),
        });
    } catch (_e) {
        // Bulk email is best-effort.
    }
}

async function persistDelivery(
    adminClient: SupabaseClient,
    event: NotificationEventRecord,
    device: DeviceRecord,
    result: DeliveryResult,
): Promise<void> {
    const payload = {
        event_id: event.id,
        device_id: device.id,
        user_id: device.user_id,
        provider: device.push_provider,
        status: result.status,
        provider_message_id: result.providerMessageId ?? null,
        error_code: result.errorCode ?? null,
        error_message: result.errorMessage ?? null,
        sent_at: result.status === "sent" ? new Date().toISOString() : null,
        updated_at: new Date().toISOString(),
    };

    const { error } = await adminClient.from("notification_deliveries").upsert(payload, {
        onConflict: "event_id,device_id",
    });

    if (error) {
        throw new Error(error.message);
    }

    if (result.status === "invalid_token") {
        await adminClient
            .from("user_devices")
            .update({
                is_active: false,
                deactivated_at: new Date().toISOString(),
                updated_at: new Date().toISOString(),
                metadata: {
                    last_push_error: result.errorMessage ?? result.errorCode ?? "invalid_token",
                },
            })
            .eq("id", device.id);
    }
}

async function processNotificationEvent(adminClient: SupabaseClient, event: NotificationEventRecord): Promise<Response> {
    if (!event.id) {
        throw new Error("Notification event is missing an id");
    }

    const lockedEvent = await lockNotificationEvent(adminClient, event.id);
    if (!lockedEvent) {
        return jsonResponse({ ok: true, skipped: true, reason: "already processed or locked" });
    }

    const recipientUserIds = await resolveRecipientUserIds(adminClient, lockedEvent);
    const pushEnabledUserIds = await resolvePushEnabledRecipients(adminClient, recipientUserIds);
    const skipPush = Boolean((lockedEvent.data as JsonObject).skip_push);
    const eligibleDevices = skipPush
        ? []
        : await fetchDevices(adminClient, Array.from(pushEnabledUserIds), lockedEvent.push_provider);

    await upsertInAppNotifications(adminClient, lockedEvent, recipientUserIds);
    // If this is a chat message, booking alert, or follow notification and an email
    // provider is configured, also send an email copy to recipients.
    const mailtrapToken = Deno.env.get('MAILTRAP_API_TOKEN') ?? '';
    const mailtrapFromEmail = Deno.env.get('MAILTRAP_FROM_EMAIL') ?? 'no-reply@flexpilatesstudio.com';
    const mailtrapFromName = Deno.env.get('MAILTRAP_FROM_NAME') ?? 'Flex Pilates Studio';
    const sendgridKey = Deno.env.get('SENDGRID_API_KEY') ?? '';
    const sendgridFrom = Deno.env.get('SENDGRID_FROM') ?? '';
    const emailEligibleEvents = new Set([
        'chat_message',
        'booking_staff_notified',
        'coach_session_assigned',
        'session_updated',
        'session_spot_opened',
        'session_cancelled',
    ]);
    if (emailEligibleEvents.has(lockedEvent.event_type)) {
        const emailableUserIds = await resolveEmailEnabledRecipients(adminClient, recipientUserIds);
        const userEmails = await resolveUserEmails(adminClient, emailableUserIds);
        const recipientEmails = emailableUserIds
            .map((uid) => userEmails.get(uid))
            .filter((email): email is string => Boolean(email));

        try {
            if (mailtrapToken && mailtrapFromEmail) {
                await sendMailtrapBulk(
                    mailtrapToken,
                    mailtrapFromEmail,
                    mailtrapFromName,
                    recipientEmails,
                    lockedEvent.title,
                    lockedEvent.body,
                );
            } else if (sendgridKey && sendgridFrom) {
                for (const toEmail of recipientEmails) {
                    await sendEmailSendGrid(sendgridKey, sendgridFrom, toEmail, lockedEvent.title, lockedEvent.body);
                }
            }
        } catch (_e) {
            // Non-fatal — emails are best-effort here
        }
    }
    const deliveryResults = skipPush
        ? []
        : await Promise.all(
            eligibleDevices.map(async (device) => {
                const result = await sendPushToDevice(device, lockedEvent);
                await persistDelivery(adminClient, lockedEvent, device, result);
                return result;
            }),
        );

    const successfulDeliveries = deliveryResults.filter((item) => item.status === "sent").length;
    const failedDeliveries = deliveryResults.filter((item) => item.status === "failed" || item.status === "invalid_token").length;

    await adminClient
        .from("notification_events")
        .update({
            status: failedDeliveries > 0 && successfulDeliveries === 0 ? "failed" : "sent",
            processed_at: new Date().toISOString(),
            last_error: failedDeliveries > 0 && successfulDeliveries === 0 ? "All deliveries failed" : null,
            updated_at: new Date().toISOString(),
        })
        .eq("id", lockedEvent.id);

    return jsonResponse({
        ok: true,
        event_id: lockedEvent.id,
        recipient_count: recipientUserIds.length,
        push_enabled_recipient_count: Array.from(pushEnabledUserIds).length,
        delivery_count: eligibleDevices.length,
        sent_count: successfulDeliveries,
        failed_count: failedDeliveries,
        in_app_count: recipientUserIds.length,
        skip_push: skipPush,
    });
}

serve(async (req) => {
    if (req.method === "OPTIONS") {
        return new Response("ok", { headers: corsHeaders });
    }

    if (req.method !== "POST") {
        return jsonResponse({ error: "Method not allowed" }, 405);
    }

    try {
        const adminClient = await createAdminClient();
        const authorization = await authorizeRequest(req, adminClient);
        const payload = await req.json().catch(() => ({}));

        if (isFollowNotificationRequest(payload)) {
            const followRequest = normalizeFollowNotificationRequest(payload);
            const event = await buildFollowNotificationEvent(adminClient, followRequest, authorization);

            if (!event) {
                return jsonResponse({ ok: true, skipped: true, reason: 'no recipients' });
            }

            const resolvedEvent = await resolveEvent(adminClient, event, authorization.userId);
            return await processNotificationEvent(adminClient, resolvedEvent);
        }

        if (authorization.mode !== "webhook" && authorization.role !== "admin") {
            return jsonResponse({ error: "Forbidden" }, 403);
        }

        const event = normalizeNotificationEvent(payload);

        if (!event.title || !event.body) {
            return jsonResponse({ error: "Missing notification title or body" }, 400);
        }

        const resolvedEvent = await resolveEvent(adminClient, event, authorization.userId);
        return await processNotificationEvent(adminClient, resolvedEvent);
    } catch (error) {
        const message = error instanceof Error ? error.message : "Unknown error";
        const status = message === "Unauthorized" ? 401 : message === "Forbidden" ? 403 : 500;
        return jsonResponse({ error: message }, status);
    }
});