// ============================================================
//  EcoRover App — RoverMode enum
// ============================================================

enum RoverMode {
  idle,
  manual,
  autonomous,
  motion;

  static RoverMode fromString(String? s) {
    switch (s?.toUpperCase()) {
      case 'MANUAL':
        return RoverMode.manual;
      case 'AUTONOMOUS':
        return RoverMode.autonomous;
      case 'MOTION':
        return RoverMode.motion;
      default:
        return RoverMode.idle;
    }
  }

  bool get isAutomatic =>
      this == RoverMode.autonomous || this == RoverMode.motion;
}

// ============================================================
//  DriveCommand enum — maps exactly to V6 drive states
// ============================================================

enum DriveCommand {
  forward,
  backward,
  left,
  right,
  strafeLeft,
  strafeRight,
  spinLeft,
  spinRight,
  diagFL,
  diagFR,
  diagBL,
  diagBR,
  stop;

  /// The V6 API path segment for this command
  String get apiPath {
    switch (this) {
      case DriveCommand.forward:
        return 'forward';
      case DriveCommand.backward:
        return 'backward';
      case DriveCommand.left:
        return 'left';
      case DriveCommand.right:
        return 'right';
      case DriveCommand.strafeLeft:
        return 'strafe-left';
      case DriveCommand.strafeRight:
        return 'strafe-right';
      case DriveCommand.spinLeft:
        return 'spin-left';
      case DriveCommand.spinRight:
        return 'spin-right';
      case DriveCommand.diagFL:
        return 'diag-fl';
      case DriveCommand.diagFR:
        return 'diag-fr';
      case DriveCommand.diagBL:
        return 'diag-bl';
      case DriveCommand.diagBR:
        return 'diag-br';
      case DriveCommand.stop:
        return 'stop';
    }
  }

  /// Parse the V6 drive state string from /api/status
  static DriveCommand? fromStatusString(String? s) {
    switch (s?.toUpperCase()) {
      case 'FORWARD':
        return DriveCommand.forward;
      case 'BACKWARD':
        return DriveCommand.backward;
      case 'LEFT':
        return DriveCommand.left;
      case 'RIGHT':
        return DriveCommand.right;
      case 'STRAFE_LEFT':
        return DriveCommand.strafeLeft;
      case 'STRAFE_RIGHT':
        return DriveCommand.strafeRight;
      case 'SPIN_LEFT':
        return DriveCommand.spinLeft;
      case 'SPIN_RIGHT':
        return DriveCommand.spinRight;
      case 'DIAG_FL':
        return DriveCommand.diagFL;
      case 'DIAG_FR':
        return DriveCommand.diagFR;
      case 'DIAG_BL':
        return DriveCommand.diagBL;
      case 'DIAG_BR':
        return DriveCommand.diagBR;
      case 'STOP':
        return DriveCommand.stop;
      default:
        return null;
    }
  }
}
