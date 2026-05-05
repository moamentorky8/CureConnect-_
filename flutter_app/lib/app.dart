import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show DateFormat;

class CureConnectApp extends StatefulWidget {
  const CureConnectApp({super.key});

  @override
  State<CureConnectApp> createState() => _CureConnectAppState();
}

class _CureConnectAppState extends State<CureConnectApp> {
  AppTab _activeTab = AppTab.home;
  bool _sosTriggered = false;

  final List<MedicationDose> _medications = <MedicationDose>[
    MedicationDose(
      id: '1',
      name: 'Metformin',
      dosage: '500 mg',
      time: '08:00 AM',
      period: DosePeriod.morning,
      status: DoseStatus.taken,
    ),
    MedicationDose(
      id: '2',
      name: 'Vitamin D',
      dosage: '1000 IU',
      time: '08:30 AM',
      period: DosePeriod.morning,
      status: DoseStatus.taken,
    ),
    MedicationDose(
      id: '3',
      name: 'Lisinopril',
      dosage: '10 mg',
      time: '01:00 PM',
      period: DosePeriod.afternoon,
      status: DoseStatus.taken,
    ),
    MedicationDose(
      id: '4',
      name: 'Aspirin',
      dosage: '81 mg',
      time: '06:00 PM',
      period: DosePeriod.evening,
      status: DoseStatus.pending,
    ),
    MedicationDose(
      id: '5',
      name: 'Atorvastatin',
      dosage: '20 mg',
      time: '09:00 PM',
      period: DosePeriod.evening,
      status: DoseStatus.pending,
    ),
  ];

  final List<ReportPoint> _heartRateData = const <ReportPoint>[
    ReportPoint('00:00', 68),
    ReportPoint('04:00', 62),
    ReportPoint('08:00', 75),
    ReportPoint('12:00', 82),
    ReportPoint('16:00', 78),
    ReportPoint('20:00', 70),
    ReportPoint('Now', 75),
  ];

  final List<ReportPoint> _temperatureData = const <ReportPoint>[
    ReportPoint('00:00', 36.5),
    ReportPoint('04:00', 36.3),
    ReportPoint('08:00', 36.8),
    ReportPoint('12:00', 37.1),
    ReportPoint('16:00', 37.0),
    ReportPoint('20:00', 36.7),
    ReportPoint('Now', 37.0),
  ];

  final List<WeeklyVital> _weeklyVitals = const <WeeklyVital>[
    WeeklyVital('Mon', 72, 36.8),
    WeeklyVital('Tue', 75, 36.9),
    WeeklyVital('Wed', 70, 37.0),
    WeeklyVital('Thu', 78, 36.7),
    WeeklyVital('Fri', 74, 36.8),
    WeeklyVital('Sat', 71, 36.6),
    WeeklyVital('Sun', 75, 37.0),
  ];

  final List<EmergencyEvent> _emergencyEvents = const <EmergencyEvent>[
    EmergencyEvent('High Heart Rate', '120 bpm', 'May 3, 2026', '14:32'),
    EmergencyEvent('Missed Medication', 'Metformin', 'May 2, 2026', '09:15'),
    EmergencyEvent('Low Temperature', '35.2 C', 'Apr 30, 2026', '06:45'),
  ];

  HardwareState _hardware = const HardwareState(
    ldrValue: 720,
    ldrStatus: 'Bright',
    alarmActive: false,
    lastPing: '2 seconds ago',
    pwmIntensity: 75,
    autoMode: true,
  );

  ProfileState _profile = const ProfileState(
    notifications: true,
    voiceAlerts: true,
    autoSync: true,
    darkMode: true,
    syncStatus: SyncStatus.synced,
    projectId: 'cureconnect-xxxxx',
    databaseUrl: 'https://cureconnect-xxxxx.firebaseio.com',
    apiKey: 'AIza...',
    voiceApiKey: 'sk-...',
    voiceId: 'Rachel',
    language: 'en-US',
  );

  ReportRange _reportRange = ReportRange.today;

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF07111E),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF00D9A5),
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CureConnect',
      theme: baseTheme.copyWith(
        appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent),
      ),
      home: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color(0xFF081423),
                Color(0xFF05101A),
                Color(0xFF03070D),
              ],
            ),
          ),
          child: Stack(
            children: <Widget>[
              const Positioned(
                top: -120,
                left: -40,
                child: _GlowBubble(
                  size: 260,
                  colors: <Color>[Color(0x6600D9A5), Color(0x0000D9A5)],
                ),
              ),
              const Positioned(
                top: 220,
                right: -100,
                child: _GlowBubble(
                  size: 220,
                  colors: <Color>[Color(0x44007BFF), Color(0x00007BFF)],
                ),
              ),
              SafeArea(
                child: Column(
                  children: <Widget>[
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: KeyedSubtree(
                            key: ValueKey<AppTab>(_activeTab),
                            child: _buildCurrentPage(),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _BottomNavBar(
                        activeTab: _activeTab,
                        onSelect: (AppTab tab) {
                          setState(() => _activeTab = tab);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_activeTab) {
      case AppTab.home:
        return _buildDashboard();
      case AppTab.schedule:
        return _buildMedicationSchedule();
      case AppTab.hardware:
        return _buildHardwarePage();
      case AppTab.reports:
        return _buildReportsPage();
      case AppTab.settings:
        return _buildSettingsPage();
    }
  }

  Widget _buildDashboard() {
    final int taken = _medications
        .where((MedicationDose m) => m.status == DoseStatus.taken)
        .length;
    final int pending = _medications
        .where((MedicationDose m) => m.status == DoseStatus.pending)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _PageHeader(
          eyebrow: 'Good Morning',
          title: 'Welcome, Moamen',
          trailing: const _AvatarBadge(label: 'M'),
        ),
        const SizedBox(height: 20),
        const _GlassCard(
          padding: EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              _StatusDot(color: Color(0xFF22C55E)),
              SizedBox(width: 10),
              Icon(Icons.wifi_rounded, color: Color(0xFF22C55E)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'ESP32 Connected',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                'Last sync: Just now',
                style: TextStyle(fontSize: 12, color: Color(0xFF93A4B8)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('Real-time Vitals', style: _Styles.sectionTitle),
        const SizedBox(height: 14),
        const Row(
          children: <Widget>[
            Expanded(
              child: _MetricCard(
                title: 'Heart Rate',
                value: '75',
                unit: 'bpm',
                icon: Icons.favorite_rounded,
                iconColor: Color(0xFFEF4444),
                statusLabel: 'Normal',
                statusColor: Color(0xFF22C55E),
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: _MetricCard(
                title: 'Body Temp',
                value: '37',
                unit: 'C',
                icon: Icons.device_thermostat_rounded,
                iconColor: Color(0xFFF59E0B),
                statusLabel: 'Normal',
                statusColor: Color(0xFF22C55E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        _GlassCard(
          child: Column(
            children: <Widget>[
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
                  SizedBox(width: 8),
                  Text('Emergency Zone', style: _Styles.sectionTitle),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Press the SOS button to alert your emergency contacts and medical team.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _Styles.mutedText, height: 1.45),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _triggerSos,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 220),
                  scale: _sosTriggered ? 1.08 : 1,
                  child: Container(
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: <Color>[Color(0xFFEF4444), Color(0xFFB91C1C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x66EF4444),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'SOS',
                      style:
                          TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ),
              if (_sosTriggered) ...<Widget>[
                const SizedBox(height: 14),
                const Text(
                  'Emergency alert triggered successfully.',
                  style: TextStyle(
                    color: Color(0xFFFCA5A5),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        _GlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Today\'s Summary',
                style: TextStyle(
                  fontSize: 14,
                  color: _Styles.mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _SummaryStat(
                        value: '$taken/${_medications.length}',
                        label: 'Doses Taken',
                        color: const Color(0xFF00D9A5)),
                  ),
                  Expanded(
                    child: _SummaryStat(
                        value: '0',
                        label: 'Alerts Today',
                        color: const Color(0xFF007BFF)),
                  ),
                  Expanded(
                    child: _SummaryStat(
                        value: '$pending',
                        label: 'Pending',
                        color: const Color(0xFFF59E0B)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMedicationSchedule() {
    final Map<DosePeriod, List<MedicationDose>> grouped =
        <DosePeriod, List<MedicationDose>>{
      for (final DosePeriod period in DosePeriod.values)
        period: _medications
            .where((MedicationDose m) => m.period == period)
            .toList(),
    };

    final int taken = _medications
        .where((MedicationDose m) => m.status == DoseStatus.taken)
        .length;
    final double progress =
        _medications.isEmpty ? 0 : taken / _medications.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _PageHeader(
          title: 'Medication Schedule',
          eyebrow: DateFormat('EEEE, MMM d y').format(DateTime.now()),
          trailing: IconButton.filled(
            onPressed: _showAddMedicationSheet,
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              shape: const CircleBorder(),
              padding: EdgeInsets.zero,
            ),
            icon: Ink(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: <Color>[Color(0xFF00D9A5), Color(0xFF00C4D9)],
                ),
              ),
              child: const Icon(Icons.add_rounded, color: Colors.black),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Text(
                    'Daily Progress',
                    style: TextStyle(
                        color: _Styles.mutedText, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    '$taken/${_medications.length} taken',
                    style: const TextStyle(
                      color: Color(0xFF00D9A5),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: const Color(0xFF1A2532),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF00D9A5)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        for (final DosePeriod period in DosePeriod.values)
          if (grouped[period]!.isNotEmpty) ...<Widget>[
            _PeriodHeader(period: period),
            const SizedBox(height: 14),
            ...grouped[period]!.map(_buildMedicationTile),
            const SizedBox(height: 18),
          ],
      ],
    );
  }

  Widget _buildHardwarePage() {
    final double lightProgress = _hardware.ldrValue / 1024;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _PageHeader(
          title: 'Hardware Management',
          eyebrow: 'ESP32 Smart Medication Organizer',
        ),
        const SizedBox(height: 20),
        _GlassCard(
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  const _IconBadge(
                      icon: Icons.memory_rounded, color: Color(0xFF007BFF)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('ESP32-WROOM-32',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        SizedBox(height: 2),
                        Text(
                          'Medication Organizer v1.2',
                          style:
                              TextStyle(fontSize: 12, color: _Styles.mutedText),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _refreshHardware,
                    icon: const Icon(Icons.refresh_rounded),
                    color: Colors.white,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0x221C2A39),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Row(
                children: <Widget>[
                  Expanded(
                    child: _InlineStatusCard(
                      icon: Icons.wifi_rounded,
                      label: 'Connection',
                      value: 'Online',
                      color: Color(0xFF22C55E),
                    ),
                  ),
                  SizedBox(width: 12),
                ],
              ),
              const SizedBox(height: 12),
              _InlineStatusCard(
                icon: Icons.timeline_rounded,
                label: 'Last Ping',
                value: _hardware.lastPing,
                color: const Color(0xFF00D9A5),
                fullWidth: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Row(
                children: <Widget>[
                  _IconBadge(
                      icon: Icons.wb_sunny_rounded, color: Color(0xFFF59E0B)),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('LDR Light Sensor',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      SizedBox(height: 2),
                      Text(
                        'Ambient light detection',
                        style:
                            TextStyle(fontSize: 12, color: _Styles.mutedText),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _Styles.innerCardDecoration,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text('Current Reading',
                              style: TextStyle(
                                  fontSize: 13, color: _Styles.mutedText)),
                          const SizedBox(height: 6),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(fontFamily: 'inherit'),
                              children: <InlineSpan>[
                                const TextSpan(
                                  text: '',
                                  style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900),
                                ),
                                TextSpan(
                                  text: '${_hardware.ldrValue}',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    foreground: Paint()
                                      ..shader = const LinearGradient(
                                        colors: <Color>[
                                          Color(0xFF00D9A5),
                                          Color(0xFF00C4D9)
                                        ],
                                      ).createShader(
                                          const Rect.fromLTWH(0, 0, 200, 70)),
                                  ),
                                ),
                                const TextSpan(
                                  text: ' / 1024',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _Styles.mutedText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: <Widget>[
                        Icon(
                          Icons.lightbulb_rounded,
                          size: 34,
                          color: _hardware.ldrStatus == 'Bright'
                              ? const Color(0xFFF59E0B)
                              : _hardware.ldrStatus == 'Dim'
                                  ? const Color(0xFF00D9A5)
                                  : const Color(0xFF007BFF),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _hardware.ldrStatus,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: lightProgress,
                  minHeight: 12,
                  backgroundColor: const Color(0xFF1A2532),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF00D9A5)),
                ),
              ),
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text('Dark',
                      style: TextStyle(fontSize: 12, color: _Styles.mutedText)),
                  Text('Dim',
                      style: TextStyle(fontSize: 12, color: _Styles.mutedText)),
                  Text('Bright',
                      style: TextStyle(fontSize: 12, color: _Styles.mutedText)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _GlassCard(
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  const _IconBadge(
                      icon: Icons.tune_rounded, color: Color(0xFF00D9A5)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('PWM LED Control',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        SizedBox(height: 2),
                        Text('Indicator brightness',
                            style: TextStyle(
                                fontSize: 12, color: _Styles.mutedText)),
                      ],
                    ),
                  ),
                  const Text('Auto',
                      style: TextStyle(color: _Styles.mutedText)),
                  const SizedBox(width: 8),
                  Switch(
                    value: _hardware.autoMode,
                    onChanged: (bool value) {
                      setState(() =>
                          _hardware = _hardware.copyWith(autoMode: value));
                    },
                    activeThumbColor: Colors.black,
                    activeTrackColor: const Color(0xFF00D9A5),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Opacity(
                opacity: _hardware.autoMode ? 0.5 : 1,
                child: IgnorePointer(
                  ignoring: _hardware.autoMode,
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Text('Intensity',
                              style: TextStyle(color: _Styles.mutedText)),
                          const Spacer(),
                          Text(
                            '${_hardware.pwmIntensity}%',
                            style: const TextStyle(
                              color: Color(0xFF00D9A5),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _hardware.pwmIntensity.toDouble(),
                        min: 0,
                        max: 100,
                        divisions: 100,
                        activeColor: const Color(0xFF00D9A5),
                        onChanged: (double value) {
                          setState(() => _hardware =
                              _hardware.copyWith(pwmIntensity: value.round()));
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Row(
                children: <Widget>[
                  _IconBadge(
                      icon: Icons.notifications_active_rounded,
                      color: Color(0xFFEF4444)),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Manual Alarm',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      SizedBox(height: 2),
                      Text('Test medication reminder',
                          style: TextStyle(
                              fontSize: 12, color: _Styles.mutedText)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _Styles.innerCardDecoration,
                child: Row(
                  children: <Widget>[
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Alarm Status',
                              style: TextStyle(
                                  fontSize: 13, color: _Styles.mutedText)),
                          SizedBox(height: 4),
                        ],
                      ),
                    ),
                    Text(
                      _hardware.alarmActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _hardware.alarmActive
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF22C55E),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _hardware.alarmActive
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF22C55E),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _triggerHardwareAlarm,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: const Color(0xFFEF4444),
                ),
                icon: const Icon(Icons.notifications_active_rounded),
                label: Text(_hardware.alarmActive
                    ? 'Alarm Triggered!'
                    : 'Trigger Manual Alarm'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Device Information', style: _Styles.sectionTitle),
              SizedBox(height: 16),
              _InfoRow(label: 'Firmware Version', value: 'v1.2.3'),
              _InfoRow(label: 'MAC Address', value: 'A4:CF:12:XX:XX:XX'),
              _InfoRow(label: 'IP Address', value: '192.168.1.105'),
              _InfoRow(label: 'Uptime', value: '5 days, 12 hours'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReportsPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _PageHeader(
          title: 'Health Reports',
          eyebrow: 'Monitor your vitals history',
        ),
        const SizedBox(height: 20),
        _GlassCard(
          padding: const EdgeInsets.all(6),
          child: Row(
            children: ReportRange.values.map((ReportRange range) {
              final bool selected = range == _reportRange;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _reportRange = range),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: selected
                          ? const LinearGradient(
                              colors: <Color>[
                                Color(0xFF00D9A5),
                                Color(0xFF00C4D9)
                              ],
                            )
                          : null,
                    ),
                    child: Text(
                      range.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: selected ? Colors.black : _Styles.mutedText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 18),
        const Row(
          children: <Widget>[
            Expanded(
              child: _ReportSummaryCard(
                title: 'Avg Heart Rate',
                value: '74',
                unit: 'bpm',
                delta: '-3% from last week',
                icon: Icons.favorite_rounded,
                iconColor: Color(0xFFEF4444),
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: _ReportSummaryCard(
                title: 'Avg Temperature',
                value: '36.8',
                unit: 'C',
                delta: 'Normal range',
                icon: Icons.device_thermostat_rounded,
                iconColor: Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _ChartCard(
          title: 'Heart Rate',
          subtitle: 'Beats per minute',
          value: '75 bpm',
          icon: Icons.favorite_rounded,
          iconColor: const Color(0xFFEF4444),
          child: _LineChart(
            points: _heartRateData,
            strokeColor: const Color(0xFFEF4444),
            fillColor: const Color(0x33EF4444),
            minY: 50,
            maxY: 100,
          ),
        ),
        const SizedBox(height: 20),
        _ChartCard(
          title: 'Body Temperature',
          subtitle: 'Degrees Celsius',
          value: '37 C',
          icon: Icons.device_thermostat_rounded,
          iconColor: const Color(0xFFF59E0B),
          child: _LineChart(
            points: _temperatureData,
            strokeColor: const Color(0xFF00D9A5),
            fillColor: const Color(0x3300D9A5),
            minY: 35,
            maxY: 38,
          ),
        ),
        const SizedBox(height: 20),
        _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Row(
                children: <Widget>[
                  _IconBadge(
                      icon: Icons.calendar_month_rounded,
                      color: Color(0xFF007BFF)),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Weekly Overview',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      SizedBox(height: 2),
                      Text('Last 7 days summary',
                          style: TextStyle(
                              fontSize: 12, color: _Styles.mutedText)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _weeklyVitals.map((WeeklyVital vital) {
                  final double height =
                      ((vital.heartRate - 60) / 30).clamp(0, 1) * 70 + 12;
                  return Expanded(
                    child: Column(
                      children: <Widget>[
                        Text(vital.day,
                            style: const TextStyle(
                                fontSize: 12, color: _Styles.mutedText)),
                        const SizedBox(height: 8),
                        Container(
                          height: 86,
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            height: height,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: const LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: <Color>[
                                  Color(0x99EF4444),
                                  Color(0x33EF4444)
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('${vital.heartRate}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const _IconBadge(
                      icon: Icons.warning_amber_rounded,
                      color: Color(0xFFEF4444)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Emergency Alerts',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        SizedBox(height: 2),
                        Text('Past week',
                            style: TextStyle(
                                fontSize: 12, color: _Styles.mutedText)),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: const Color(0x3322C55E),
                    ),
                    child: const Text(
                      'All Resolved',
                      style: TextStyle(
                        color: Color(0xFF22C55E),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ..._emergencyEvents.map((EmergencyEvent event) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: _Styles.innerCardDecoration,
                    child: Row(
                      children: <Widget>[
                        const _StatusDot(color: Color(0xFF22C55E)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(event.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(event.value,
                                  style: const TextStyle(
                                      color: _Styles.mutedText)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Text(event.date,
                                style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 2),
                            Text(event.time,
                                style: const TextStyle(
                                    fontSize: 12, color: _Styles.mutedText)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _PageHeader(
          title: 'Settings',
          eyebrow: 'Manage your profile and preferences',
        ),
        const SizedBox(height: 20),
        const _GlassCard(
          child: Row(
            children: <Widget>[
              _AvatarBadge(label: 'MA', size: 72),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Moamen Abdel-Fattah',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800)),
                    SizedBox(height: 4),
                    Text('moamen@example.com',
                        style: TextStyle(color: _Styles.mutedText)),
                    SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        _StatusDot(color: Color(0xFF22C55E)),
                        SizedBox(width: 8),
                        Text(
                          'Active Patient',
                          style: TextStyle(
                              color: Color(0xFF22C55E),
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: _Styles.mutedText),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _GlassCard(
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  const _IconBadge(
                      icon: Icons.cloud_sync_rounded, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Firebase Sync',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        SizedBox(height: 2),
                        Text('Realtime Database',
                            style: TextStyle(
                                fontSize: 12, color: _Styles.mutedText)),
                      ],
                    ),
                  ),
                  _SyncBadge(status: _profile.syncStatus),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton(
                      onPressed: _startSync,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: const Color(0xFF00D9A5),
                        foregroundColor: Colors.black,
                      ),
                      child: Text(_profile.syncStatus == SyncStatus.syncing
                          ? 'Syncing...'
                          : 'Sync Now'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _showFirebaseConfigSheet,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        side: const BorderSide(color: Color(0x333A4B61)),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Configure'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _GlassCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const _IconBadge(
                icon: Icons.mic_rounded, color: Color(0xFF007BFF)),
            title: const Text('Voice Preferences',
                style: TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(
              '${_profile.voiceId} • ${_profile.language}',
              style: const TextStyle(color: _Styles.mutedText),
            ),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: _Styles.mutedText),
            onTap: _showVoiceConfigSheet,
          ),
        ),
        const SizedBox(height: 20),
        _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('Quick Settings', style: _Styles.sectionTitle),
              const SizedBox(height: 12),
              _SettingsToggleTile(
                icon: Icons.notifications_rounded,
                title: 'Push Notifications',
                subtitle: 'Medication reminders',
                value: _profile.notifications,
                onChanged: (bool value) {
                  setState(
                      () => _profile = _profile.copyWith(notifications: value));
                },
              ),
              _SettingsToggleTile(
                icon: Icons.volume_up_rounded,
                title: 'Voice Alerts',
                subtitle: 'Spoken reminders via ESP32',
                value: _profile.voiceAlerts,
                onChanged: (bool value) {
                  setState(
                      () => _profile = _profile.copyWith(voiceAlerts: value));
                },
              ),
              _SettingsToggleTile(
                icon: Icons.storage_rounded,
                title: 'Auto Sync',
                subtitle: 'Sync data automatically',
                value: _profile.autoSync,
                onChanged: (bool value) {
                  setState(() => _profile = _profile.copyWith(autoSync: value));
                },
              ),
              _SettingsToggleTile(
                icon: Icons.shield_rounded,
                title: 'Dark Mode',
                subtitle: 'Always enabled',
                value: _profile.darkMode,
                enabled: false,
                onChanged: (_) {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const _ActionButton(
          icon: Icons.person_rounded,
          label: 'Edit Profile',
        ),
        const SizedBox(height: 12),
        const _ActionButton(
          icon: Icons.verified_user_rounded,
          label: 'Privacy & Security',
        ),
        const SizedBox(height: 12),
        const _ActionButton(
          icon: Icons.logout_rounded,
          label: 'Sign Out',
          danger: true,
        ),
        const SizedBox(height: 22),
        const Center(
          child: Column(
            children: <Widget>[
              Text('CureConnect v1.0.0',
                  style: TextStyle(color: _Styles.mutedText)),
              SizedBox(height: 4),
              Text('Smart Medication Organizer',
                  style: TextStyle(fontSize: 12, color: _Styles.mutedText)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMedicationTile(MedicationDose medication) {
    final Color statusColor = switch (medication.status) {
      DoseStatus.taken => const Color(0xFF22C55E),
      DoseStatus.missed => const Color(0xFFEF4444),
      DoseStatus.pending => const Color(0xFFF59E0B),
    };

    final String statusLabel = switch (medication.status) {
      DoseStatus.taken => 'Taken',
      DoseStatus.missed => 'Missed',
      DoseStatus.pending => 'Pending',
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: _GlassCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 16,
              height: 16,
              margin: const EdgeInsets.only(top: 26),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor,
                border: Border.all(color: const Color(0xFF07111E), width: 3),
              ),
            ),
            const SizedBox(width: 14),
            const _IconBadge(
                icon: Icons.medication_rounded, color: Color(0xFF00D9A5)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(medication.name,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(medication.dosage,
                      style: const TextStyle(color: _Styles.mutedText)),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      const Icon(Icons.schedule_rounded,
                          size: 14, color: _Styles.mutedText),
                      const SizedBox(width: 6),
                      Text(
                        medication.time,
                        style: const TextStyle(
                            fontSize: 12, color: _Styles.mutedText),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (medication.status == DoseStatus.pending)
              Column(
                children: <Widget>[
                  _CircleActionButton(
                    icon: Icons.check_rounded,
                    color: const Color(0xFF22C55E),
                    onTap: () => _updateMedicationStatus(
                        medication.id, DoseStatus.taken),
                  ),
                  const SizedBox(height: 8),
                  _CircleActionButton(
                    icon: Icons.close_rounded,
                    color: const Color(0xFFEF4444),
                    onTap: () => _updateMedicationStatus(
                        medication.id, DoseStatus.missed),
                  ),
                ],
              )
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: statusColor.withValues(alpha: 0.18),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                      color: statusColor, fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _triggerSos() {
    setState(() => _sosTriggered = true);
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _sosTriggered = false);
      }
    });
  }

  void _updateMedicationStatus(String id, DoseStatus status) {
    setState(() {
      final int index =
          _medications.indexWhere((MedicationDose m) => m.id == id);
      if (index != -1) {
        _medications[index] = _medications[index].copyWith(status: status);
      }
    });
  }

  void _showAddMedicationSheet() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController dosageController = TextEditingController();
    final TextEditingController timeController = TextEditingController();
    DosePeriod selectedPeriod = DosePeriod.morning;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0C1724),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context,
              void Function(void Function()) setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Add Medication', style: _Styles.sectionTitle),
                  const SizedBox(height: 16),
                  _InputField(
                      controller: nameController,
                      label: 'Medication Name',
                      hint: 'e.g. Metformin'),
                  const SizedBox(height: 12),
                  _InputField(
                      controller: dosageController,
                      label: 'Dosage',
                      hint: 'e.g. 500 mg'),
                  const SizedBox(height: 12),
                  _InputField(
                      controller: timeController,
                      label: 'Time',
                      hint: 'e.g. 08:00 AM'),
                  const SizedBox(height: 12),
                  const Text('Period',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<DosePeriod>(
                    initialValue: selectedPeriod,
                    dropdownColor: const Color(0xFF0F1D2D),
                    decoration: _Styles.inputDecoration(),
                    items: DosePeriod.values.map((DosePeriod period) {
                      return DropdownMenuItem<DosePeriod>(
                        value: period,
                        child: Text(period.label),
                      );
                    }).toList(),
                    onChanged: (DosePeriod? value) {
                      if (value != null) {
                        setSheetState(() => selectedPeriod = value);
                      }
                    },
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: () {
                      if (nameController.text.trim().isEmpty ||
                          dosageController.text.trim().isEmpty ||
                          timeController.text.trim().isEmpty) {
                        return;
                      }
                      setState(() {
                        _medications.add(
                          MedicationDose(
                            id: DateTime.now()
                                .microsecondsSinceEpoch
                                .toString(),
                            name: nameController.text.trim(),
                            dosage: dosageController.text.trim(),
                            time: timeController.text.trim(),
                            period: selectedPeriod,
                            status: DoseStatus.pending,
                          ),
                        );
                      });
                      Navigator.of(context).pop();
                    },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      backgroundColor: const Color(0xFF00D9A5),
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Add Medication'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _refreshHardware() {
    final math.Random random = math.Random();
    final int nextValue = 300 + random.nextInt(724);
    final String status = nextValue > 700
        ? 'Bright'
        : nextValue > 450
            ? 'Dim'
            : 'Dark';
    setState(() {
      _hardware = _hardware.copyWith(
        ldrValue: nextValue,
        ldrStatus: status,
        lastPing: 'Just now',
      );
    });
  }

  void _triggerHardwareAlarm() {
    setState(() => _hardware = _hardware.copyWith(alarmActive: true));
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _hardware = _hardware.copyWith(alarmActive: false));
      }
    });
  }

  void _startSync() {
    setState(
        () => _profile = _profile.copyWith(syncStatus: SyncStatus.syncing));
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(
            () => _profile = _profile.copyWith(syncStatus: SyncStatus.synced));
      }
    });
  }

  void _showFirebaseConfigSheet() {
    final TextEditingController projectController =
        TextEditingController(text: _profile.projectId);
    final TextEditingController databaseController =
        TextEditingController(text: _profile.databaseUrl);
    final TextEditingController apiKeyController =
        TextEditingController(text: _profile.apiKey);

    _showConfigSheet(
      title: 'Firebase Configuration',
      content: <Widget>[
        _InputField(controller: projectController, label: 'Project ID'),
        const SizedBox(height: 12),
        _InputField(controller: databaseController, label: 'Database URL'),
        const SizedBox(height: 12),
        _InputField(controller: apiKeyController, label: 'API Key'),
      ],
      onSave: () {
        setState(() {
          _profile = _profile.copyWith(
            projectId: projectController.text.trim(),
            databaseUrl: databaseController.text.trim(),
            apiKey: apiKeyController.text.trim(),
          );
        });
      },
    );
  }

  void _showVoiceConfigSheet() {
    final TextEditingController apiController =
        TextEditingController(text: _profile.voiceApiKey);
    String voiceId = _profile.voiceId;
    String language = _profile.language;

    _showConfigSheet(
      title: 'Voice Settings',
      content: <Widget>[
        _InputField(controller: apiController, label: 'ElevenLabs API Key'),
        const SizedBox(height: 12),
        StatefulBuilder(
          builder: (BuildContext context,
              void Function(void Function()) setModalState) {
            return Column(
              children: <Widget>[
                DropdownButtonFormField<String>(
                  initialValue: voiceId,
                  dropdownColor: const Color(0xFF0F1D2D),
                  decoration: _Styles.inputDecoration(label: 'Voice'),
                  items: const <String>['Rachel', 'Adam', 'Josh', 'Bella']
                      .map((String value) => DropdownMenuItem<String>(
                          value: value, child: Text(value)))
                      .toList(),
                  onChanged: (String? value) {
                    if (value != null) {
                      setModalState(() => voiceId = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: language,
                  dropdownColor: const Color(0xFF0F1D2D),
                  decoration: _Styles.inputDecoration(label: 'Language'),
                  items: const <String>['en-US', 'en-GB', 'ar-EG', 'es-ES']
                      .map((String value) => DropdownMenuItem<String>(
                          value: value, child: Text(value)))
                      .toList(),
                  onChanged: (String? value) {
                    if (value != null) {
                      setModalState(() => language = value);
                    }
                  },
                ),
              ],
            );
          },
        ),
      ],
      onSave: () {
        setState(() {
          _profile = _profile.copyWith(
            voiceApiKey: apiController.text.trim(),
            voiceId: voiceId,
            language: language,
          );
        });
      },
    );
  }

  void _showConfigSheet({
    required String title,
    required List<Widget> content,
    required VoidCallback onSave,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0C1724),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: _Styles.sectionTitle),
              const SizedBox(height: 16),
              ...content,
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () {
                  onSave();
                  Navigator.of(context).pop();
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: const Color(0xFF00D9A5),
                  foregroundColor: Colors.black,
                ),
                child: const Text('Save Settings'),
              ),
            ],
          ),
        );
      },
    );
  }
}

enum AppTab {
  home('Home', Icons.home_rounded),
  schedule('Schedule', Icons.calendar_month_rounded),
  hardware('Device', Icons.memory_rounded),
  reports('Reports', Icons.bar_chart_rounded),
  settings('Settings', Icons.settings_rounded);

  const AppTab(this.label, this.icon);

  final String label;
  final IconData icon;
}

enum DoseStatus { taken, missed, pending }

enum DosePeriod {
  morning('Morning', Icons.wb_sunny_rounded),
  afternoon('Afternoon', Icons.wb_twilight_rounded),
  evening('Evening', Icons.nights_stay_rounded);

  const DosePeriod(this.label, this.icon);

  final String label;
  final IconData icon;
}

enum ReportRange {
  today('Today'),
  week('Week'),
  month('Month');

  const ReportRange(this.label);

  final String label;
}

enum SyncStatus { synced, syncing, error }

class MedicationDose {
  const MedicationDose({
    required this.id,
    required this.name,
    required this.dosage,
    required this.time,
    required this.period,
    required this.status,
  });

  final String id;
  final String name;
  final String dosage;
  final String time;
  final DosePeriod period;
  final DoseStatus status;

  MedicationDose copyWith({
    String? id,
    String? name,
    String? dosage,
    String? time,
    DosePeriod? period,
    DoseStatus? status,
  }) {
    return MedicationDose(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      time: time ?? this.time,
      period: period ?? this.period,
      status: status ?? this.status,
    );
  }
}

class ReportPoint {
  const ReportPoint(this.label, this.value);

  final String label;
  final double value;
}

class WeeklyVital {
  const WeeklyVital(this.day, this.heartRate, this.temperature);

  final String day;
  final int heartRate;
  final double temperature;
}

class EmergencyEvent {
  const EmergencyEvent(this.title, this.value, this.date, this.time);

  final String title;
  final String value;
  final String date;
  final String time;
}

class HardwareState {
  const HardwareState({
    required this.ldrValue,
    required this.ldrStatus,
    required this.alarmActive,
    required this.lastPing,
    required this.pwmIntensity,
    required this.autoMode,
  });

  final int ldrValue;
  final String ldrStatus;
  final bool alarmActive;
  final String lastPing;
  final int pwmIntensity;
  final bool autoMode;

  HardwareState copyWith({
    int? ldrValue,
    String? ldrStatus,
    bool? alarmActive,
    String? lastPing,
    int? pwmIntensity,
    bool? autoMode,
  }) {
    return HardwareState(
      ldrValue: ldrValue ?? this.ldrValue,
      ldrStatus: ldrStatus ?? this.ldrStatus,
      alarmActive: alarmActive ?? this.alarmActive,
      lastPing: lastPing ?? this.lastPing,
      pwmIntensity: pwmIntensity ?? this.pwmIntensity,
      autoMode: autoMode ?? this.autoMode,
    );
  }
}

class ProfileState {
  const ProfileState({
    required this.notifications,
    required this.voiceAlerts,
    required this.autoSync,
    required this.darkMode,
    required this.syncStatus,
    required this.projectId,
    required this.databaseUrl,
    required this.apiKey,
    required this.voiceApiKey,
    required this.voiceId,
    required this.language,
  });

  final bool notifications;
  final bool voiceAlerts;
  final bool autoSync;
  final bool darkMode;
  final SyncStatus syncStatus;
  final String projectId;
  final String databaseUrl;
  final String apiKey;
  final String voiceApiKey;
  final String voiceId;
  final String language;

  ProfileState copyWith({
    bool? notifications,
    bool? voiceAlerts,
    bool? autoSync,
    bool? darkMode,
    SyncStatus? syncStatus,
    String? projectId,
    String? databaseUrl,
    String? apiKey,
    String? voiceApiKey,
    String? voiceId,
    String? language,
  }) {
    return ProfileState(
      notifications: notifications ?? this.notifications,
      voiceAlerts: voiceAlerts ?? this.voiceAlerts,
      autoSync: autoSync ?? this.autoSync,
      darkMode: darkMode ?? this.darkMode,
      syncStatus: syncStatus ?? this.syncStatus,
      projectId: projectId ?? this.projectId,
      databaseUrl: databaseUrl ?? this.databaseUrl,
      apiKey: apiKey ?? this.apiKey,
      voiceApiKey: voiceApiKey ?? this.voiceApiKey,
      voiceId: voiceId ?? this.voiceId,
      language: language ?? this.language,
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.title,
    this.eyebrow,
    this.trailing,
  });

  final String title;
  final String? eyebrow;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (eyebrow != null)
                Text(
                  eyebrow!,
                  style: const TextStyle(
                    color: _Styles.mutedText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.activeTab,
    required this.onSelect,
  });

  final AppTab activeTab;
  final ValueChanged<AppTab> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xCC0E1826),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0x26394A5F)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: AppTab.values.map((AppTab tab) {
          final bool isActive = tab == activeTab;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(tab),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: isActive
                      ? const LinearGradient(
                          colors: <Color>[Color(0xFF00D9A5), Color(0xFF00C4D9)],
                        )
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(tab.icon,
                        color: isActive ? Colors.black : _Styles.mutedText),
                    const SizedBox(height: 4),
                    Text(
                      tab.label,
                      style: TextStyle(
                        fontSize: 11,
                        color: isActive ? Colors.black : _Styles.mutedText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: const Color(0xCC101A28),
        border: Border.all(color: const Color(0x1F42546C)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.iconColor,
    required this.statusLabel,
    required this.statusColor,
  });

  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color iconColor;
  final String statusLabel;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _IconBadge(icon: icon, color: iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style:
                      const TextStyle(fontSize: 13, color: _Styles.mutedText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontFamily: 'inherit'),
              children: <InlineSpan>[
                TextSpan(
                  text: value,
                  style: const TextStyle(
                      fontSize: 38, fontWeight: FontWeight.w900),
                ),
                TextSpan(
                  text: ' $unit',
                  style:
                      const TextStyle(fontSize: 13, color: _Styles.mutedText),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              _StatusDot(color: statusColor),
              const SizedBox(width: 8),
              Text(
                statusLabel,
                style:
                    TextStyle(color: statusColor, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          value,
          style: TextStyle(
              fontSize: 28, fontWeight: FontWeight.w900, color: color),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: _Styles.mutedText),
        ),
      ],
    );
  }
}

class _PeriodHeader extends StatelessWidget {
  const _PeriodHeader({required this.period});

  final DosePeriod period;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _IconBadge(icon: period.icon, color: const Color(0xFF007BFF)),
        const SizedBox(width: 12),
        Text(period.label, style: _Styles.sectionTitle),
      ],
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.18),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

class _InlineStatusCard extends StatelessWidget {
  const _InlineStatusCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.fullWidth = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(14),
      decoration: _Styles.innerCardDecoration,
      child: Row(
        children: <Widget>[
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label,
                  style:
                      const TextStyle(fontSize: 12, color: _Styles.mutedText)),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(color: color, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  final String title;
  final String subtitle;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _IconBadge(icon: icon, color: iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: _Styles.mutedText)),
                  ],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF00D9A5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(height: 180, child: child),
        ],
      ),
    );
  }
}

class _LineChart extends StatelessWidget {
  const _LineChart({
    required this.points,
    required this.strokeColor,
    required this.fillColor,
    required this.minY,
    required this.maxY,
  });

  final List<ReportPoint> points;
  final Color strokeColor;
  final Color fillColor;
  final double minY;
  final double maxY;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _LineChartPainter(
            points: points,
            strokeColor: strokeColor,
            fillColor: fillColor,
            minY: minY,
            maxY: maxY,
          ),
        );
      },
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.points,
    required this.strokeColor,
    required this.fillColor,
    required this.minY,
    required this.maxY,
  });

  final List<ReportPoint> points;
  final Color strokeColor;
  final Color fillColor;
  final double minY;
  final double maxY;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) {
      return;
    }

    const double topPadding = 12;
    const double bottomPadding = 28;
    final double usableHeight = size.height - topPadding - bottomPadding;
    final double stepX =
        points.length == 1 ? 0 : size.width / (points.length - 1);

    final Paint gridPaint = Paint()
      ..color = const Color(0x223C4A5D)
      ..strokeWidth = 1;
    for (int i = 0; i < 4; i++) {
      final double y = topPadding + usableHeight * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final Path linePath = Path();
    final Path fillPath = Path();

    for (int i = 0; i < points.length; i++) {
      final ReportPoint point = points[i];
      final double normalized =
          ((point.value - minY) / (maxY - minY)).clamp(0, 1);
      final double x = stepX * i;
      final double y = topPadding + usableHeight * (1 - normalized);

      if (i == 0) {
        linePath.moveTo(x, y);
        fillPath.moveTo(x, size.height - bottomPadding);
        fillPath.lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      canvas.drawCircle(
        Offset(x, y),
        4,
        Paint()..color = strokeColor,
      );

      final TextPainter labelPainter = TextPainter(
        text: TextSpan(
          text: point.label,
          style: const TextStyle(fontSize: 11, color: _Styles.mutedText),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      labelPainter.paint(
          canvas, Offset(x - labelPainter.width / 2, size.height - 18));
    }

    fillPath.lineTo(size.width, size.height - bottomPadding);
    fillPath.close();

    canvas.drawPath(fillPath, Paint()..color = fillColor);
    canvas.drawPath(
      linePath,
      Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.fillColor != fillColor;
  }
}

class _SettingsToggleTile extends StatelessWidget {
  const _SettingsToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          _IconBadge(
              icon: icon,
              color: const Color(0xFF00D9A5),
              background: const Color(0x221B2837)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: _Styles.mutedText)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeTrackColor: const Color(0xFF00D9A5),
            activeThumbColor: Colors.black,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final Color accent = danger ? const Color(0xFFEF4444) : Colors.white;

    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        side: BorderSide(
            color: danger ? const Color(0x66EF4444) : const Color(0x333A4B61)),
        backgroundColor: danger ? const Color(0x14EF4444) : Colors.transparent,
        foregroundColor: accent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: accent),
          const SizedBox(width: 12),
          Text(label),
          const Spacer(),
          if (!danger)
            const Icon(Icons.chevron_right_rounded, color: _Styles.mutedText),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    this.hint,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: _Styles.inputDecoration(label: label, hint: hint),
    );
  }
}

class _SyncBadge extends StatelessWidget {
  const _SyncBadge({required this.status});

  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (status) {
      SyncStatus.synced => const Color(0xFF22C55E),
      SyncStatus.syncing => const Color(0xFF007BFF),
      SyncStatus.error => const Color(0xFFEF4444),
    };

    final String label = switch (status) {
      SyncStatus.synced => 'Synced',
      SyncStatus.syncing => 'Syncing',
      SyncStatus.error => 'Error',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            status == SyncStatus.syncing
                ? Icons.sync_rounded
                : Icons.check_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({
    required this.label,
    this.size = 48,
  });

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: <Color>[Color(0xFF00D9A5), Color(0xFF00C4D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: Colors.black,
          fontSize: size * 0.34,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.color,
    this.background,
  });

  final IconData icon;
  final Color color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: color),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child:
                Text(label, style: const TextStyle(color: _Styles.mutedText)),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ReportSummaryCard extends StatelessWidget {
  const _ReportSummaryCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.delta,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final String value;
  final String unit;
  final String delta;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style:
                      const TextStyle(fontSize: 12, color: _Styles.mutedText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontFamily: 'inherit'),
              children: <InlineSpan>[
                TextSpan(
                  text: value,
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w900),
                ),
                TextSpan(
                  text: ' $unit',
                  style:
                      const TextStyle(fontSize: 12, color: _Styles.mutedText),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            delta,
            style: const TextStyle(
              color: Color(0xFF22C55E),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowBubble extends StatelessWidget {
  const _GlowBubble({
    required this.size,
    required this.colors,
  });

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}

class _Styles {
  static const Color mutedText = Color(0xFF93A4B8);

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
  );

  static const BoxDecoration innerCardDecoration = BoxDecoration(
    color: Color(0x99152230),
    borderRadius: BorderRadius.all(Radius.circular(20)),
  );

  static InputDecoration inputDecoration({String? label, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFF132030),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0x333A4B61)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0x333A4B61)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF00D9A5)),
      ),
    );
  }
}
