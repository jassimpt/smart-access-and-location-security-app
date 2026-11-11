enum AutoLockDuration {
  immediately(0),
  thirtySeconds(30),
  oneMinute(60),
  fiveMinutes(300);

  const AutoLockDuration(this.seconds);
  final int seconds;
  Duration get duration => Duration(seconds: seconds);
}
