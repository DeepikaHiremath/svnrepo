package gw.rating.flow

uses gw.api.database.Query
uses java.util.Set
uses java.util.HashSet

enhancement RateTableArgumentSourceSetEnhancement : entity.RateTableArgumentSourceSet {

  /**
   * Used to check whether or not the associated rate table argument set is in use by
   * a rate routine which is referenced in a promoted (non-draft) rate book.
   *
   * @return Returns true if the rate table argument source set is used in a rate routine
   * referenced in a non-draft (promoted) rate book, else return false.
   */
  function isUsedInPromotedBookViaRoutine(): boolean {
    return statusesOfRateBooksReferencingRoutine().hasMatch(\rateBookStatus -> rateBookStatus != TC_DRAFT)
  }

  /**
   * Used to check whether or not the associated rate table argument set is in use by
   * a rate routine which is referenced in any rate book.
   *
   * @return Returns true if the rate table argument source set is used in a rate routine
   * referenced in any rate book, else return false.
   */
  function isUsedInAnyRateBookViaRateRoutine(): boolean {
    return statusesOfRateBooksReferencingRoutine().HasElements
  }

  /**
   * Determine the set of rate book statuses for the rate books that reference rate
   * routines that use this rate table argument source set.
   *
   * @return Set The set of rate book statuses for rate books that contain rate routines
   *             which use this rate table argument source set.
   */
  private function statusesOfRateBooksReferencingRoutine(): Set<RateBookStatus> {
    var stepOperandsQuery = Query.make(CalcStepDefinitionOperand)
        .compare("TableCode", Equals, this.RateTableDefinition.TableCode)
        .compare("ArgumentSourceSetCode", Equals, this.Code)
    var stepOperands = stepOperandsQuery.select()
    var defs = stepOperands*.CalcStep*.CalcRoutineDefinition.toSet()
    // Process rate book statuses for each CalcRoutineDefinition to avoid creating large results during expansions
    return defs.map(\d -> d.RateBooks*.Status.toSet())
        .reduce(new HashSet<RateBookStatus>() as Set<RateBookStatus>, (\s, t -> s.union(t)))
  }

  /**
   * Query to return all routines using the argument source set and rate table definition
   */
  property get ReferencingRateRoutines(): List<CalcRoutineDefinition> {
    return Query.make(CalcRoutineDefinition)
        .join(CalcStepDefinition, "CalcRoutineDefinition")
        .join(CalcStepDefinitionOperand, "CalcStep")
        .compare("TableCode", Equals, this.RateTableDefinition.TableCode)
        .compare("ArgumentSourceSetCode", Equals, this.Code)
        .select()
        .toList()
  }

  property get NotUsedByRateRoutines(): Boolean {
    return this.ReferencingRateRoutines.Empty
  }
}
