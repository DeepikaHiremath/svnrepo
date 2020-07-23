package gw.rating.rtm.query

uses gw.rating.rtm.matchop.InterpolatingMatchOperator
uses gw.rating.rtm.matchop.StatelessMatchOperator

enhancement StatelessMatchOperatorListEnhancement: List<StatelessMatchOperator> {
  /**
   * Returns the sorting order of MatchOps. The order [determined by Priority] is preserved and only
   * eventual Interpolated MatchOp(s) are moved over to the end.
   */
  function getSortOrder(numOps: int): int[] {
    var seq = new int[numOps]
    var reorderCount = 0
    for (i in 0..|numOps) {
      var op = this.get(i)
      if (op typeis InterpolatingMatchOperator) {
        reorderCount++
        seq[numOps - reorderCount] = i
      } else {
        seq[i - reorderCount] = i
      }
    }
    return seq
  }
}
