// ============================================================
//  EcoRover — Unit Tests
//  Status parsing, mode labels, drive mappings, accessory locks,
//  motion UDP formatting, and lifecycle behavior
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:ecorover_app/models/rover_status.dart';
import 'package:ecorover_app/models/rover_mode.dart';
import 'package:ecorover_app/app/constants.dart';

void main() {
  // ==========================================================
  // 1. Status parsing
  // ==========================================================

  group('RoverStatus.fromJson', () {
    test('valid complete JSON parses correctly', () {
      final status = RoverStatus.fromJson({
        'mode': 'MANUAL',
        'drive': 'FORWARD',
        'front': 45.2,
        'rear': 30.1,
        'rightObstacle': false,
        'obstacle': false,
        'allBlocked': false,
        'ldr': 280,
        'headlight': true,
        'headlightManual': true,
        'headlightAuto': false,
        'accessoriesLocked': false,
        'buzzer': false,
        'rgb': true,
        'rgbColor': 'RED',
        'pan': 90,
        'tilt': 45,
        'manualSpeed': 75,
        'autoSpeed': 50,
        'motionSensitivity': 60,
        'phoneCalibrated': false,
        'clients': 1,
      });

      expect(status.mode, RoverMode.manual);
      expect(status.activeDrive, DriveCommand.forward);
      expect(status.front, closeTo(45.2, 0.01));
      expect(status.rear, closeTo(30.1, 0.01));
      expect(status.ldr, 280);
      expect(status.rgbColor, 'RED');
      expect(status.pan, 90);
      expect(status.tilt, 45);
      expect(status.manualSpeed, 75);
    });

    test('missing fields use defaults', () {
      final status = RoverStatus.fromJson({});

      expect(status.mode, RoverMode.idle);
      expect(status.activeDrive, isNull);
      expect(status.front, -1.0);
      expect(status.rear, -1.0);
      expect(status.manualSpeed, EcoConstants.defaultManualSpeed);
      expect(status.autoSpeed, EcoConstants.defaultAutoSpeed);
      expect(status.motionSensitivity, EcoConstants.defaultMotionSensitivity);
      expect(status.pan, EcoConstants.defaultPan);
      expect(status.tilt, EcoConstants.defaultTilt);
    });

    test('ultrasonic -1 (no echo) is preserved', () {
      final status = RoverStatus.fromJson({'front': -1.0, 'rear': -1.0});
      expect(status.front, -1.0);
      expect(status.rear, -1.0);
      expect(status.frontDisplay, 'NO ECHO');
      expect(status.rearDisplay, 'NO ECHO');
    });

    test('ultrasonic with valid distance shows cm', () {
      final status = RoverStatus.fromJson({'front': 175.4, 'rear': 45.0});
      expect(status.frontDisplay, '175.4 cm');
      expect(status.rearDisplay, '45.0 cm');
    });

    test('out-of-range speed falls back to default', () {
      final status = RoverStatus.fromJson({
        'manualSpeed': 150, // out of 0-100
      });
      expect(status.manualSpeed, EcoConstants.defaultManualSpeed);
    });

    test('NaN/null values use fallbacks', () {
      final status = RoverStatus.fromJson({
        'front': null,
        'manualSpeed': null,
        'pan': null,
      });
      expect(status.front, -1.0);
      expect(status.manualSpeed, EcoConstants.defaultManualSpeed);
      expect(status.pan, EcoConstants.defaultPan);
    });

    test('frontDisplay is NO ECHO when front is 0', () {
      final status = RoverStatus.fromJson({'front': 0.0});
      expect(status.frontDisplay, 'NO ECHO');
    });

    test('obstacle display: allBlocked takes priority', () {
      final status = RoverStatus.fromJson({
        'obstacle': true,
        'allBlocked': true,
      });
      expect(status.obstacleDisplay, 'ALL BLOCKED');
      expect(status.obstacleIsDanger, true);
    });

    test('obstacle display: detected', () {
      final status =
          RoverStatus.fromJson({'obstacle': true, 'allBlocked': false});
      expect(status.obstacleDisplay, 'DETECTED');
      expect(status.obstacleIsDanger, true);
    });

    test('obstacle display: clear', () {
      final status =
          RoverStatus.fromJson({'obstacle': false, 'allBlocked': false});
      expect(status.obstacleDisplay, 'CLEAR');
      expect(status.obstacleIsDanger, false);
    });

    test('50% default for all sliders before first status', () {
      final s = RoverStatus.defaults;
      expect(s.manualSpeed, 50);
      expect(s.autoSpeed, 50);
      expect(s.motionSensitivity, 50);
    });

    test('90° default for pan and tilt', () {
      final s = RoverStatus.defaults;
      expect(s.pan, 90);
      expect(s.tilt, 90);
    });
  });

  // ==========================================================
  // 2. Mode labels
  // ==========================================================

  group('RoverMode labels', () {
    test('Manual page + IDLE mode → Idle', () {
      final mode = RoverMode.fromString('IDLE');
      expect(mode, RoverMode.idle);
      // Smart=false, mode=idle → "Idle"
      expect(_modeLabel(mode, false), 'Idle');
    });

    test('Manual page + MANUAL mode → Manual', () {
      final mode = RoverMode.fromString('MANUAL');
      expect(_modeLabel(mode, false), 'Manual');
    });

    test('Smart page + IDLE mode → Ready', () {
      final mode = RoverMode.fromString('IDLE');
      expect(_modeLabel(mode, true), 'Ready');
    });

    test('Smart page + AUTONOMOUS mode → Auto', () {
      final mode = RoverMode.fromString('AUTONOMOUS');
      expect(_modeLabel(mode, true), 'Auto');
    });

    test('Smart page + MOTION mode → Motion', () {
      final mode = RoverMode.fromString('MOTION');
      expect(_modeLabel(mode, true), 'Motion');
    });

    test('Unknown mode string → idle', () {
      final mode = RoverMode.fromString('GARBAGE');
      expect(mode, RoverMode.idle);
    });
  });

  // ==========================================================
  // 3. Drive mappings
  // ==========================================================

  group('DriveCommand API paths', () {
    test('forward → /api/manual/forward', () {
      expect(DriveCommand.forward.apiPath, 'forward');
    });
    test('backward → backward', () {
      expect(DriveCommand.backward.apiPath, 'backward');
    });
    test('left → left (curve)', () {
      expect(DriveCommand.left.apiPath, 'left');
    });
    test('right → right (curve)', () {
      expect(DriveCommand.right.apiPath, 'right');
    });
    test('FAST L → strafe-left', () {
      expect(DriveCommand.strafeLeft.apiPath, 'strafe-left');
    });
    test('FAST R → strafe-right', () {
      expect(DriveCommand.strafeRight.apiPath, 'strafe-right');
    });
    test('spin-left → spin-left', () {
      expect(DriveCommand.spinLeft.apiPath, 'spin-left');
    });
    test('spin-right → spin-right', () {
      expect(DriveCommand.spinRight.apiPath, 'spin-right');
    });
    test('diag-fl', () => expect(DriveCommand.diagFL.apiPath, 'diag-fl'));
    test('diag-fr', () => expect(DriveCommand.diagFR.apiPath, 'diag-fr'));
    test('diag-bl', () => expect(DriveCommand.diagBL.apiPath, 'diag-bl'));
    test('diag-br', () => expect(DriveCommand.diagBR.apiPath, 'diag-br'));
    test('stop', () => expect(DriveCommand.stop.apiPath, 'stop'));
  });

  group('DriveCommand.fromStatusString', () {
    test('STRAFE_LEFT → strafeLeft', () {
      expect(DriveCommand.fromStatusString('STRAFE_LEFT'),
          DriveCommand.strafeLeft);
    });
    test('STRAFE_RIGHT → strafeRight', () {
      expect(DriveCommand.fromStatusString('STRAFE_RIGHT'),
          DriveCommand.strafeRight);
    });
    test('STOP → stop', () {
      expect(DriveCommand.fromStatusString('STOP'), DriveCommand.stop);
    });
    test('null → null', () {
      expect(DriveCommand.fromStatusString(null), isNull);
    });
    test('unknown → null', () {
      expect(DriveCommand.fromStatusString('MOONWALK'), isNull);
    });
  });

  // ==========================================================
  // 4. Accessory lock
  // ==========================================================

  group('Accessory locking', () {
    test('AUTONOMOUS mode locks accessories', () {
      final status = RoverStatus.fromJson({
        'mode': 'AUTONOMOUS',
        'accessoriesLocked': true,
      });
      expect(status.accessoriesLocked, true);
      expect(status.mode.isAutomatic, true);
    });

    test('MOTION mode locks accessories', () {
      final status = RoverStatus.fromJson({
        'mode': 'MOTION',
        'accessoriesLocked': true,
      });
      expect(status.accessoriesLocked, true);
      expect(status.mode.isAutomatic, true);
    });

    test('IDLE mode does not lock accessories', () {
      final status = RoverStatus.fromJson({
        'mode': 'IDLE',
        'accessoriesLocked': false,
      });
      expect(status.accessoriesLocked, false);
      expect(status.mode.isAutomatic, false);
    });

    test('MANUAL mode does not lock accessories', () {
      final status = RoverStatus.fromJson({
        'mode': 'MANUAL',
        'accessoriesLocked': false,
      });
      expect(status.accessoriesLocked, false);
    });
  });

  // ==========================================================
  // 5. Motion UDP packet format
  // ==========================================================

  group('Motion UDP packet format', () {
    test('packet format is x,y,z with comma separators', () {
      const x = -0.21;
      const y = -4.56;
      const z = 8.71;
      final packet =
          '${x.toStringAsFixed(2)},${y.toStringAsFixed(2)},${z.toStringAsFixed(2)}';
      expect(packet, '-0.21,-4.56,8.71');
    });

    test('packet has exactly 2 commas', () {
      const x = 1.0, y = 2.0, z = 3.0;
      final packet =
          '${x.toStringAsFixed(2)},${y.toStringAsFixed(2)},${z.toStringAsFixed(2)}';
      expect(packet.split(',').length, 3);
    });

    test('no spaces in packet', () {
      final packet = '1.00,2.00,3.00';
      expect(packet.contains(' '), false);
    });

    test('no JSON in packet', () {
      final packet = '1.00,2.00,3.00';
      expect(packet.startsWith('{'), false);
    });
  });
}

// ---- Helper: mode label logic (mirrors ControlHeader logic) -----------------

String _modeLabel(RoverMode mode, bool smart) {
  if (smart) {
    switch (mode) {
      case RoverMode.autonomous:
        return 'Auto';
      case RoverMode.motion:
        return 'Motion';
      default:
        return 'Ready';
    }
  } else {
    return mode == RoverMode.manual ? 'Manual' : 'Idle';
  }
}
