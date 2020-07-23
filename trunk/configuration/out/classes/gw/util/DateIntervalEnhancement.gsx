package gw.util

enhancement DateIntervalEnhancement: gw.lang.reflect.interval.DateInterval {
  /**
   * Return the number of LeapDays present in this DateInterval
   */
  property get LeapDaysInInterval() : int {
    var earlier = this.LeftEndpoint
    var later = this.RightEndpoint

    if (!this.LeftClosed) {
      earlier = earlier.addDays(1)
    }
    if (!this.RightClosed) {
      later = later.addDays(-1)
    }

    return com.guidewire.pl.system.util.DateRange.allDatesBetween(earlier, later).NumOfLeapYearDays
  }
}
