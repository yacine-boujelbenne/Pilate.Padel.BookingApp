import { normalizeNotificationEvent, validateNotificationEvent } from '../lib/validators';

describe('Notification validators', () => {
    test('normalizes a simple payload', () => {
        const raw = { title: 'Hi', body: 'Hello', event_type: 'greeting' };
        const ev = normalizeNotificationEvent(raw as any);
        expect(ev.title).toBe('Hi');
        expect(ev.body).toBe('Hello');
        expect(ev.event_type).toBe('greeting');
        expect(ev.push_provider).toBe('fcm');
    });

    test('extracts record wrapper payloads', () => {
        const raw = { record: { title: 'T', body: 'B', event_type: 'e' } };
        const ev = normalizeNotificationEvent(raw as any);
        expect(ev.title).toBe('T');
        expect(ev.event_type).toBe('e');
    });

    test('validates missing fields', () => {
        const raw = { title: '', body: '' };
        const ev = normalizeNotificationEvent(raw as any);
        const res = validateNotificationEvent(ev as any);
        expect(res.valid).toBe(false);
        expect(res.errors.length).toBeGreaterThan(0);
    });
});
