# Mailtrap Integration Setup Guide

This guide walks you through setting up Mailtrap email service for the notification system in Flex Pilates Studio.

## Table of Contents
1. [Create Mailtrap Account](#create-mailtrap-account)
2. [Get API Token](#get-api-token)
3. [Create Email Templates](#create-email-templates)
4. [Environment Variables](#environment-variables)
5. [Testing the Integration](#testing-the-integration)
6. [Troubleshooting](#troubleshooting)
7. [API Documentation](#api-documentation)

---

## Create Mailtrap Account

### Step 1: Sign Up
1. Visit [Mailtrap.io](https://mailtrap.io)
2. Click **Sign Up** and create a free account
3. Choose your plan (Free tier includes up to 100 emails/month)
4. Verify your email address

### Step 2: Create a Project
1. Log in to Mailtrap dashboard
2. Click **Create Project** or go to **Projects**
3. Name your project (e.g., "Flex Pilates - Notifications")
4. Click **Create**

### Step 3: Create Inboxes
You'll need separate inboxes for different environments:
- **Development** - For testing in development
- **Staging** - For testing in staging environment (optional)
- **Production** - For live notifications

To create an inbox:
1. Inside your project, click **Create Inbox**
2. Enter a name (e.g., "Development")
3. Click **Create**
4. Repeat for other environments

---

## Get API Token

### Step 1: Access API Settings
1. From the dashboard, click **Settings** (gear icon)
2. Go to **API** tab
3. You'll see your **API Token** (keep this secret!)

### Step 2: Copy API Token
1. Click the copy icon next to your API Token
2. Store it securely in your `.env` file (see [Environment Variables](#environment-variables) section)

### Generate Multiple Tokens (Recommended)
For better security, create separate tokens for different environments:
1. In **API** settings, click **Generate New Token**
2. Name it (e.g., "development-token")
3. Select scope: "Full Access"
4. Click **Generate**
5. Repeat for staging and production

---

## Create Email Templates

Mailtrap supports dynamic email templates with variable substitution. Create templates for key notification types:

### Template 1: Session Created Notification

**Template Name:** `session_created`

**Subject:**
```
New {{session_title}} Session Available - {{date}}
```

**HTML Body:**
```html
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #6366f1; color: white; padding: 20px; border-radius: 5px; }
        .content { margin: 20px 0; }
        .button { display: inline-block; background-color: #6366f1; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; margin: 20px 0; }
        .footer { color: #666; font-size: 12px; margin-top: 30px; border-top: 1px solid #ddd; padding-top: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>New Session Available! 🎉</h1>
        </div>
        
        <div class="content">
            <p>Hi {{member_name}},</p>
            
            <p>A new {{session_title}} session has just been added to the schedule!</p>
            
            <h3>Session Details</h3>
            <ul>
                <li><strong>Class:</strong> {{session_title}}</li>
                <li><strong>Date:</strong> {{date}}</li>
                <li><strong>Time:</strong> {{time}}</li>
                <li><strong>Coach:</strong> {{coach_name}}</li>
                <li><strong>Duration:</strong> {{duration}} minutes</li>
            </ul>
            
            <p>{{spots_available}} spot(s) available!</p>
            
            <a href="{{booking_link}}" class="button">Book Now</a>
        </div>
        
        <div class="footer">
            <p>This is an automated notification from Flex Pilates Studio.</p>
            <p>You can manage notification preferences in your account settings.</p>
        </div>
    </div>
</body>
</html>
```

### Template 2: Session Attached Notification

**Template Name:** `session_attached`

**Subject:**
```
Confirmation: You're Booked for {{session_title}} on {{date}}
```

**HTML Body:**
```html
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #10b981; color: white; padding: 20px; border-radius: 5px; }
        .confirmation { background-color: #f0fdf4; border-left: 4px solid #10b981; padding: 15px; margin: 20px 0; }
        .button { display: inline-block; background-color: #10b981; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; margin: 20px 0; }
        .footer { color: #666; font-size: 12px; margin-top: 30px; border-top: 1px solid #ddd; padding-top: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Booking Confirmed ✓</h1>
        </div>
        
        <div class="confirmation">
            <p>Hi {{member_name}},</p>
            <p>Your booking is confirmed!</p>
        </div>
        
        <div class="content">
            <h3>Session Details</h3>
            <ul>
                <li><strong>Class:</strong> {{session_title}}</li>
                <li><strong>Date:</strong> {{date}}</li>
                <li><strong>Time:</strong> {{time}}</li>
                <li><strong>Coach:</strong> {{coach_name}}</li>
                <li><strong>Duration:</strong> {{duration}} minutes</li>
                <li><strong>Location:</strong> {{location}}</li>
            </ul>
            
            <p><strong>Confirmation Code:</strong> {{confirmation_code}}</p>
            
            <a href="{{session_link}}" class="button">View Session</a>
        </div>
        
        <div class="footer">
            <p>If you need to cancel, please do so at least 24 hours in advance to avoid cancellation fees.</p>
            <p>Questions? Contact us at {{support_email}}</p>
        </div>
    </div>
</body>
</html>
```

### Template 3: Waitlist Available Notification

**Template Name:** `waitlist_available`

**Subject:**
```
Great News! A Spot Opened Up for {{session_title}}
```

**HTML Body:**
```html
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #f59e0b; color: white; padding: 20px; border-radius: 5px; }
        .alert { background-color: #fffbeb; border-left: 4px solid #f59e0b; padding: 15px; margin: 20px 0; }
        .button { display: inline-block; background-color: #f59e0b; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; margin: 20px 0; }
        .footer { color: #666; font-size: 12px; margin-top: 30px; border-top: 1px solid #ddd; padding-top: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>A Spot Just Opened! 🎯</h1>
        </div>
        
        <div class="alert">
            <p>Hi {{member_name}},</p>
            <p><strong>Good news!</strong> A spot has become available in {{session_title}} that you were on the waitlist for.</p>
        </div>
        
        <div class="content">
            <h3>Session Details</h3>
            <ul>
                <li><strong>Class:</strong> {{session_title}}</li>
                <li><strong>Date:</strong> {{date}}</li>
                <li><strong>Time:</strong> {{time}}</li>
                <li><strong>Coach:</strong> {{coach_name}}</li>
            </ul>
            
            <p><strong>⏰ Hurry!</strong> This spot may be taken by another member. Book within the next hour to secure your place.</p>
            
            <a href="{{booking_link}}" class="button">Book Now</a>
        </div>
        
        <div class="footer">
            <p>If you're no longer interested in this session, you can ignore this message.</p>
        </div>
    </div>
</body>
</html>
```

### How to Create Templates in Mailtrap

1. Go to **Inboxes** → Select your inbox
2. Click **Email Templates** tab
3. Click **Create Template**
4. Enter template name (e.g., `session_created`)
5. Fill in subject and HTML body from above
6. Click **Save**
7. Note the **Template ID** (visible in template list) - you'll need this in code

---

## Environment Variables

### Step 1: Create/Update `.env` File

Create or update your `.env` file in the project root:

```env
# Mailtrap Configuration
MAILTRAP_API_TOKEN=your_api_token_here
MAILTRAP_API_URL=https://send.api.mailtrap.io/api/send

# Email Templates (use template IDs from Mailtrap dashboard)
MAILTRAP_TEMPLATE_SESSION_CREATED=session_created
MAILTRAP_TEMPLATE_SESSION_ATTACHED=session_attached
MAILTRAP_TEMPLATE_WAITLIST_AVAILABLE=waitlist_available

# Sender Email
MAILTRAP_FROM_EMAIL=notifications@flexpilates.app
MAILTRAP_FROM_NAME=Flex Pilates Studio

# Support Email
SUPPORT_EMAIL=support@flexpilates.app
```

### Step 2: Add to `.env.example`

For your team, also create/update `.env.example`:

```env
# Mailtrap Configuration
MAILTRAP_API_TOKEN=your_api_token_here
MAILTRAP_API_URL=https://send.api.mailtrap.io/api/send

# Email Templates
MAILTRAP_TEMPLATE_SESSION_CREATED=session_created
MAILTRAP_TEMPLATE_SESSION_ATTACHED=session_attached
MAILTRAP_TEMPLATE_WAITLIST_AVAILABLE=waitlist_available

# Sender Email
MAILTRAP_FROM_EMAIL=notifications@flexpilates.app
MAILTRAP_FROM_NAME=Flex Pilates Studio

# Support Email
SUPPORT_EMAIL=support@flexpilates.app
```

### Step 3: Verify `flutter_dotenv` Configuration

Ensure your `pubspec.yaml` has `flutter_dotenv` (it's already there):

```yaml
dependencies:
  flutter_dotenv: ^5.1.0

flutter:
  assets:
    - .env
```

---

## Testing the Integration

### Unit Test Example

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flex_pilates_studio/services/mailtrap_service.dart';

void main() {
  group('MailtrapService', () {
    late MailtrapService mailtrapService;

    setUp(() {
      mailtrapService = MailtrapService();
    });

    test('sendEmail should send successfully', () async {
      final result = await mailtrapService.sendEmail(
        to: 'test@example.com',
        subject: 'Test Email',
        templateId: 'session_created',
        variables: {
          'member_name': 'John Doe',
          'session_title': 'Pilates Fundamentals',
          'date': '2025-01-15',
          'time': '10:00 AM',
          'coach_name': 'Sarah',
          'duration': '60',
          'spots_available': '5',
          'booking_link': 'https://app.flexpilates.app/book/123',
        },
      );

      expect(result, isTrue);
    });

    test('sendEmail should handle errors gracefully', () async {
      final result = await mailtrapService.sendEmail(
        to: 'invalid-email',
        subject: 'Test',
        templateId: 'non_existent_template',
        variables: {},
      );

      expect(result, isFalse);
    });
  });
}
```

### Manual Testing via Postman

1. **URL:** `POST https://send.api.mailtrap.io/api/send`

2. **Headers:**
   ```
   Authorization: Bearer YOUR_API_TOKEN
   Content-Type: application/json
   ```

3. **Body:**
   ```json
   {
     "from": {
       "email": "notifications@flexpilates.app",
       "name": "Flex Pilates Studio"
     },
     "to": [
       {
         "email": "test@example.com",
         "name": "Test User"
       }
     ],
     "subject": "Test Session Notification",
     "template_id": 123456,
     "template_variables": {
       "member_name": "Test User",
       "session_title": "Pilates Fundamentals",
       "date": "2025-01-15",
       "time": "10:00 AM",
       "coach_name": "Sarah",
       "duration": "60",
       "spots_available": "5",
       "booking_link": "https://app.flexpilates.app/book/123"
     }
   }
   ```

---

## Troubleshooting

### Email Not Received

**Symptoms:** Emails aren't appearing in Mailtrap inbox

**Solutions:**
1. Check if API token is correct in `.env`
2. Verify template ID matches exactly in Mailtrap dashboard
3. Check Mailtrap logs for errors at [https://mailtrap.io/inboxes](https://mailtrap.io/inboxes)
4. Ensure all required template variables are provided
5. Verify API endpoint URL is correct: `https://send.api.mailtrap.io/api/send`

### 401 Unauthorized Error

**Symptoms:** `401 Unauthorized` or `Invalid API Token`

**Solutions:**
1. Verify API token is copied correctly (no extra spaces)
2. Regenerate a new API token if needed
3. Check token hasn't expired (regenerate in Settings)
4. Ensure `Authorization: Bearer TOKEN` header format is correct

### 422 Unprocessable Entity

**Symptoms:** `422 Unprocessable Entity` error

**Solutions:**
1. Verify `from.email` address is configured
2. Check template variables match template placeholders
3. Ensure email addresses are valid format
4. Verify `template_id` is correct integer

### Rate Limiting

**Symptoms:** `429 Too Many Requests`

**Solutions:**
1. Implement request throttling in your service
2. Check Mailtrap plan limits (Free: 100/month)
3. Upgrade plan if needed
4. Add exponential backoff retry logic

### Template Variables Not Substituting

**Symptoms:** Template shows `{{variable_name}}` instead of actual values

**Solutions:**
1. Verify variable names match exactly (case-sensitive)
2. Check `template_variables` key is included in request
3. Ensure variables object contains all placeholders used in template
4. Test with Postman first before debugging code

### Testing in Development

When testing locally, you can:
1. Use Mailtrap's test emails (create test inbox)
2. Check emails in Mailtrap dashboard, not your actual email
3. All emails go to Mailtrap, not real recipients (safe for testing)
4. Emails appear in dashboard within seconds

---

## API Documentation

For complete API documentation, visit:
- **Official Mailtrap Docs:** https://github.com/mailtrap/mailtrap-docs/blob/main/api-docs/README.md
- **Send API Endpoint:** https://send.api.mailtrap.io/api/send (POST)
- **Mailtrap Dashboard:** https://mailtrap.io

### Key API References

- **Get API Token:** Settings → API
- **Create Template:** Inboxes → Email Templates → Create Template
- **Get Template ID:** Email Templates → Select template → Note the ID
- **Test Inbox:** Create separate inbox for testing

---

## Next Steps

1. ✅ Create Mailtrap account
2. ✅ Get API token and add to `.env`
3. ✅ Create email templates
4. ✅ Implement `MailtrapService` in `lib/services/mailtrap_service.dart`
5. ✅ Run tests to verify integration
6. ✅ Integrate with notification system
7. ✅ Deploy and monitor

For questions or issues, refer to [Troubleshooting](#troubleshooting) section or consult Mailtrap's official documentation.
