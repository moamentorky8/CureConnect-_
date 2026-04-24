# CureConnect Firebase Schema

## Firestore

### Collection: `devices`

Document ID: `{deviceId}`

```json
{
  "deviceName": "CureConnect Unit",
  "ownerUid": "uid_123",
  "hardwareModel": "ESP32-DEVKIT-V4",
  "timezone": "Africa/Cairo",
  "drawerCount": 10,
  "createdAt": "2026-04-24T12:00:00Z",
  "updatedAt": "2026-04-24T12:00:00Z"
}
```

### Subcollection: `devices/{deviceId}/schedules`

```json
{
  "label": "Metformin",
  "drawer": 3,
  "time24h": "08:30",
  "days": ["Mon", "Tue", "Wed", "Thu", "Fri"],
  "enabled": true,
  "dosageNote": "1 tablet after breakfast",
  "updatedAt": "2026-04-24T12:00:00Z"
}
```

### Subcollection: `devices/{deviceId}/logs`

```json
{
  "drawer": 3,
  "status": "success",
  "batteryPercent": 78.4,
  "scheduledFor": "2026-04-24T08:30:00Z",
  "loggedAt": "2026-04-24T08:31:14Z",
  "confirmationMethod": "ir_sensor",
  "source": "firmware"
}
```

## Realtime Database

### Path: `deviceState/{deviceId}`

```json
{
  "deviceName": "CureConnect Unit",
  "batteryPercent": 78.4,
  "batteryVoltage": 3.96,
  "isOnline": true,
  "lastSync": "2026-04-24T08:31:14Z",
  "lastDoseState": "success",
  "wifiRssi": -57,
  "pendingCommandDrawer": null
}
```

### Path: `commands/{deviceId}`

```json
{
  "type": "remote_trigger",
  "drawer": 4,
  "issuedAt": 1777022400000,
  "issuedBy": "uid_123",
  "status": "pending"
}
```

The device acknowledges by rewriting:

```json
{
  "type": "remote_trigger",
  "drawer": 4,
  "issuedAt": 1777022400000,
  "issuedBy": "uid_123",
  "status": "completed",
  "completedAt": "2026-04-24T08:32:04Z"
}
```

## Recommended Auth Model

- Flutter app users authenticate with Firebase Auth email/password.
- Each device document stores its `ownerUid`.
- App clients may only read and mutate their own device branch.
- Firmware should use a trusted ingest path in production.
- One option is a Firebase Cloud Function HTTPS endpoint with a device secret.
- Another option is a custom Firebase auth token mapped to that device.
- The Firestore rules in this repo intentionally keep mobile clients read-only for logs so app users cannot forge dose history.
