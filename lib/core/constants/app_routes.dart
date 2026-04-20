class AppRoutes {
  AppRoutes._();

  static const login = '/login';
  static const dashboard = '/dashboard';
  static const kiosk = '/kiosk/:workstationId';
  static const history = '/history';
  static const employees = '/employees';
  static const employeeNew = '/employees/new';
  static const employeeEdit = '/employees/edit/:employeeId';
  static const settings = '/settings';
  static const workstations = '/workstations';
  static const workstationNew = '/workstations/new';
  static const kioskWaiting = '/kiosk_waiting';
  static const homeEmployee = '/home-employee';
  static const myActivity = '/my-activity';
  static const myHours = '/my-hours';
  static const analytics = '/analytics';
  static const analyticsDetail = '/analytics/:employeeId';
  static const entrance = '/entrance';
  static const shifts = '/shifts';
  static const shiftNew = '/shifts/new';
}
