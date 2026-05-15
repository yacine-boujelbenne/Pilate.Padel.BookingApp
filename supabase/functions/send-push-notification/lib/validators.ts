export type JsonObject = { [k: string]: any };

export type NotificationEventRecord = {
    id?: string;
    event_type: string;
    audience_type?: 'users' | 'all' | 'roles';
    recipient_user_ids?: string[];
    recipient_roles?: string[];
    push_provider?: 'fcm' | 'expo' | 'all';
    title: string;
    body: string;
    data?: JsonObject;
    source_table?: string | null;
    source_record_id?: string | null;
};

export function toStringArray(value: any): string[] {
    if (!Array.isArray(value)) return [];
    return value.map((v) => String(v ?? '').trim()).filter(Boolean);
}

export function toJsonObject(value: any): JsonObject {
    if (value && typeof value === 'object' && !Array.isArray(value)) return value as JsonObject;
    return {};
}

export function normalizeNotificationEvent(input: any): NotificationEventRecord {
    const root = (input && typeof input === 'object') ? input : {};
    const record = (root.record && typeof root.record === 'object') ? root.record : root;

    const title = String(record.title ?? root.title ?? '').trim();
    const body = String(record.body ?? root.body ?? '').trim();
    const eventType = String(record.event_type ?? root.event_type ?? 'general').trim() || 'general';

    return {
        id: String(record.id ?? root.id ?? '').trim() || undefined,
        event_type: eventType,
        audience_type: (record.audience_type ?? root.audience_type) || 'users',
        recipient_user_ids: toStringArray(record.recipient_user_ids ?? root.recipient_user_ids),
        recipient_roles: toStringArray(record.recipient_roles ?? root.recipient_roles),
        push_provider: (record.push_provider ?? root.push_provider) || 'fcm',
        title,
        body,
        data: toJsonObject(record.data ?? root.data),
        source_table: String(record.source_table ?? root.source_table ?? '').trim() || null,
        source_record_id: String(record.source_record_id ?? root.source_record_id ?? '').trim() || null,
    };
}

export function validateNotificationEvent(ev: NotificationEventRecord): { valid: boolean; errors: string[] } {
    const errors: string[] = [];
    if (!ev.title || ev.title.length === 0) errors.push('title is required');
    if (!ev.body || ev.body.length === 0) errors.push('body is required');
    if (!ev.event_type || ev.event_type.length === 0) errors.push('event_type is required');
    return { valid: errors.length === 0, errors };
}
