package gw.rating.rtm

uses gw.api.database.DBFunction
uses gw.api.database.Query
uses gw.api.productmodel.PolicyLinePatternLookup
uses gw.api.system.PCDependenciesGateway
uses gw.api.util.DisplayableException
uses gw.api.util.LocaleUtil
uses gw.rating.CostData
uses gw.rating.flow.domain.CalcRoutine
uses gw.rating.flow.util.QueryUtils
uses gw.rating.rtm.query.RateBookQueryFilter
uses gw.rating.rtm.query.RatingQueryFacade
uses gw.rating.worksheet.domain.WorksheetEntryContainer
uses gw.validation.PCValidationContext

uses java.lang.IllegalStateException
uses java.util.ArrayList
uses java.util.Date
uses java.util.Map
uses java.util.Set
uses gw.api.rating.RatingException
uses gw.api.util.LocationUtil
uses gw.api.database.Relop

enhancement RateBookEnhancement : entity.RateBook {

  property get SelectedRateTables() : RateTable[] {
    return this.RateTables
  }

  property get OwnedTables() : RateTable[] {
    return this.RateTables.where(\ rt ->  rt.Owned)
  }

  function removeRateBook() {
    this.RateTables.each(\ rt -> rt.removeWithFactors())
    this.remove()
  }

  function addRateTable(table : RateTableDefinition) : RateTable {
    return addRateTables({table}).first()
  }

  function addRateTables(definitions : RateTableDefinition[]) : List<RateTable> {
    //refresh the definitions before validating
    definitions.each(\ def -> def.refresh())
    checkValidDefinitions(definitions)
    var ret = new ArrayList<RateTable>(definitions.Count)
    definitions.each(\ def -> ret.add(RateTableFactory.createNew(this, def)))
    //ret.each( \ elt -> this.addToRateTables(elt))
    return ret
  }

  function checkValidDefinitions(definitions : RateTableDefinition[]) {
    if (containInvalidDefs(definitions)) {
      var invalidEntities = definitions.where(\ def -> not def.hasValidEntity())
      throw new DisplayableException(displaykey.Web.Rating.Errors.InvalidEntity(invalidEntities*.TableCode.join(", ")))
    }
    //rate book policy line should match the rate table def's policy line, or the rate table def's policy line should be null
    var invalidLines = definitions.where(\ def -> def.PolicyLine != null and def.PolicyLine != this.PolicyLine)
    if(invalidLines.HasElements){
      throw new DisplayableException(displaykey.Web.Rating.Errors.InvalidPolicyLine(invalidLines*.TableCode.join(", ")))
    }
  }

  function containInvalidDefs(definitions : RateTableDefinition[]) : boolean {
    return definitions.hasMatch(\ def -> !def.hasValidEntity())
  }

  function removeRateTables(rateTables : RateTable[]) {
    rateTables.each(\ t -> t.removeWithFactors())
  }

  function availableRateTables(policyLine : String) : RateTableDefinition[] {
    // TODO: do we need a query at all?  There's a cache of RateTableDefinition objects.
    var allTables = Query.make(RateTableDefinition).or(\q -> {
          q.compare("PolicyLine", Equals, null) //null means rate table is available on any line
          if (policyLine <> null) {
            q.compare("PolicyLine", Equals, policyLine)
          }
        }).select().toTypedArray()
    return allTables.subtract(this.SelectedRateTables*.Definition).toTypedArray()
  }

  /**
   * Changes the status of the ratebook.  It also updates the last status change date for the ratebook.
   * Validation of the books state before change status can be enabled or disabled using the validate
   * parameter.
   *
   * @param status newStatus status to change the rate book to
   * @param validate If true, validate the current book's state before changing to the target status
   *                 If false, validation is skipped
   */
  function changeStatusTo(newStatus : RateBookStatus, validate : boolean) {
    if (validate) {
      switch (newStatus) {
        case TC_ACTIVE:
        case TC_APPROVED:
        case TC_DRAFT:
          break
        case TC_STAGE:
          validateChangeToStage()
          break
        default:
          throw new IllegalStateException("Failed to change unknown status: " + newStatus.DisplayName)
      }
    }
    StatusAndUpdateChangeDate = newStatus
  }

  private property set StatusAndUpdateChangeDate(newStatus : RateBookStatus) {
      this.Status = newStatus
      this.LastStatusChangeDate = Date.CurrentDate
    }

  function stage(val : RateBookUIValidator) {
    val.validateBookForUI(:rateBook = this, :status = TC_STAGE, :checkForStateChange = true)

    StatusAndUpdateChangeDate = RateBookStatus.TC_STAGE
  }

  function approve(val : RateBookUIValidator) {
    val.validateBookForUI(:rateBook = this, :status = TC_APPROVED, :checkForStateChange = true)

    StatusAndUpdateChangeDate = RateBookStatus.TC_APPROVED
  }

  function returnToDraft() {
    StatusAndUpdateChangeDate = RateBookStatus.TC_DRAFT
  }

  function activate(val : RateBookUIValidator) {
    val.validateBookForUI(:rateBook = this, :status = TC_ACTIVE, :checkForStateChange = true)

    StatusAndUpdateChangeDate = RateBookStatus.TC_ACTIVE
  }

  function hasTablesAndFactors() : boolean {
    return (this.RateTables.Count > 0) and
           !this.RateTables.hasMatch(\ rt -> rt.Factors.Empty)
  }

  function tablesWithDefinitionChanges() : List<RateTable> {
    return this.RateTables.where(\ rt -> rt.LastTableRowEdit < rt.Definition.UpdateTime).toList()
  }

  // Create a new rate book, prepopulating it with the same rate tables as the
  // existing Active (in production) rate book.  The name/version/description of the new rate book
  // will need to be set by the user.
  function versionRateBook() : RateBook {
    var newRateBook = copyBook()
    this.RateTables.each(\ srcTable -> {
      newRateBook.addReferenceRateTable(srcTable)
    })
    newRateBook.addCalcRoutines( this.CalcRoutines )
    return newRateBook
  }

  private function validateChangeToStage() {
    var ctx = new PCValidationContext("default")
    new RateBookValidation(ctx, this, :forStatus = TC_STAGE, :checkForStateChange = true).validate()
    ctx.raiseExceptionIfProblemsFound()
  }

  private function validateChangeToApproved() {
    var ctx = new PCValidationContext("default")
    new RateBookValidation(ctx, this, :forStatus = TC_APPROVED, :checkForStateChange = true).validate()
    ctx.raiseExceptionIfProblemsFound()
  }

  private function validateChangeToActive() {
    var ctx = new PCValidationContext("default")
    new RateBookValidation(ctx, this, :forStatus = TC_ACTIVE, :checkForStateChange = true).validate()
    ctx.raiseExceptionIfProblemsFound()
  }

  public function addReferenceRateTable(rateTable: RateTable): RateTable {
    var refTable = RateTableFactory.createFrom(rateTable)
    refTable.RateBook = this
    return refTable
  }

  private function copyBook() : RateBook {
    var copy = new RateBook()
    copy.BookCode = this.BookCode
    copy.BookName = this.BookName
    copy.BookDesc = this.BookDesc
    copy.BookOffering = this.BookOffering
    copy.BookJurisdiction = this.BookJurisdiction
    copy.UWCompany = this.UWCompany
    copy.LastStatusChangeDate = Date.CurrentDate
    copy.PolicyLine = this.PolicyLine
    copy.CascadedLookup = this.CascadedLookup
    copy.BookGroup = this.BookGroup

    // copy the fields for other locales too
    var languages = gw.api.util.LocaleUtil.getAllLanguages() as LanguageType[]
    for (language in languages) {
      copy["BookName_" + language.Code] = this["BookName_" + language.Code]
      copy["BookDesc_" + language.Code] = this["BookDesc_" + language.Code]
    }

    return copy
  }

  function policyLineCodeToDescription(code : String) : String {
    return PolicyLinePatternLookup.getByCode(code).DisplayName
  }

  function isActive() : boolean {
    return this.Status == RateBookStatus.TC_ACTIVE
  }

  function isApproved() : boolean {
    return this.Status == RateBookStatus.TC_APPROVED
  }

  function isDraft() : boolean {
    return this.Status == RateBookStatus.TC_DRAFT
  }

  function isStage() : boolean {
    return this.Status == RateBookStatus.TC_STAGE
  }

  function availableUWCompanies() : UWCompany[] {
    var result = PCDependenciesGateway.getUWCompanyFinder().findUWCompanies()
    return result.toTypedArray()
  }

  property get CalcRoutines() : CalcRoutineDefinition[] {
    return this.RateBookCalcRoutines*.CalcRoutineDefinition
  }

  property get updatedCalcRoutines() : CalcRoutineDefinition[] {
    var savedRoutines = this.RateBookCalcRoutines*.CalcRoutineDefinition
    return Query.make(CalcRoutineDefinition).compareIn("ID", savedRoutines*.ID).select().toTypedArray()
  }

  function availableCalcRoutines(includeOnlyMaxVersions : boolean) : CalcRoutineDefinition[] {
    var updatedCalcRoutinesCodes = updatedCalcRoutines*.Code

    /**
     * To get the max version we would normally execute SQL like this:
     *   SELECT MAX(Version), Code, Jurisdiction FROM pc_calcroutinedefinition GROUP BY Code, Jurisdiction
     * But the Query Layer does not support an aggregate function with group by.
     * The recommended work-around is to join the table to itself and perform the MAX function on the subselect.
     * Note: Jurisdiction might be null so we need an OR restriction with an AND restriction below it.
     *   (root.juristiction = subselect.jurisdiction)
     *   OR
     *   ( (root.jurisdiction IS NULL) AND (subselect.jurisdiction IS NULL) )
     *
     */
    var q = Query.make(CalcRoutineDefinition).or(\q -> {
          q.compare("PolicyLinePatternCode", Equals, null) //null means calc routine is available on any line
          if (this.PolicyLine <> null) {
            q.compare("PolicyLinePatternCode", Equals, this.PolicyLine)
          }
        })
    if (includeOnlyMaxVersions) {
      var subselectQuery = Query.make(CalcRoutineDefinition)
      subselectQuery.compare("Code", Equals, q.getColumnRef("Code"))
      for (branchingField in CalcRoutineDefinition.BranchingFields) {
        subselectQuery.or(\ orRestriction -> {
          orRestriction.compare(branchingField, Equals, q.getColumnRef(branchingField))
          orRestriction.and(\ andRestriction -> {
            andRestriction.compare(q.getColumnRef(branchingField), Equals, null)
            andRestriction.compare(subselectQuery.getColumnRef(branchingField), Equals, null)
          })
        })
      }
      q.subselect("Version", CompareIn, subselectQuery, DBFunction.Max(subselectQuery.getColumnRef("Version")))
    }

    var rows = q.select()
    return rows.where(\ c -> not updatedCalcRoutinesCodes.contains(c.Code)).toTypedArray()
  }

  function addCalcRoutines( routines :  CalcRoutineDefinition[] ) {
    // Ensure calc routines with duplicate codes cannot be added
    if(updatedCalcRoutines*.Code.intersect(routines*.Code).Count > 0){
       throw new DisplayableException(displaykey.Java.Web.Rating.Errors.DuplicateCalcRoutineCodes)
    }

    for( routine in routines ){
      var rbcr = new RateBookCalcRoutine()
      rbcr.RateBook = this
      rbcr.CalcRoutineDefinition = routine
      this.addToRateBookCalcRoutines(rbcr)
    }

    // Display warning. Allow users to add routines with missing tables.
    var missingTables = this.RateTablesMissingInCalcRoutines
    if (missingTables.HasElements) {
      LocationUtil.addRequestScopedWarningMessage(displaykey.Web.Rating.Errors.RateTableMissingFromRateBook(missingTables))
    }
  }

  function removeCalcRoutines( routines : CalcRoutineDefinition[] ) {
    this.RateBookCalcRoutines
      .where(\ rbcr -> routines.contains(rbcr.CalcRoutineDefinition))
      .each(\ rbcr -> this.removeFromRateBookCalcRoutines(rbcr) )
  }

  function  getCalcRoutine(code : String) : CalcRoutineDefinition {
    var calcRoutineDefinition : CalcRoutineDefinition
    for (var rateBook in this.RateBookHierarchy) {
      calcRoutineDefinition = QueryUtils.getCalcRoutine(rateBook.getID(), code);

      if (calcRoutineDefinition != null) {
        return calcRoutineDefinition;
      }
    }
    throw new RatingException(displaykey.Java.Web.Rating.Errors.MissingCalcRoutineCode(this.getBookCode(),
        this.getBookEdition(), code));
  }

  function executeCalcRoutine(code : String, costData : CostData<Cost, PolicyLine>,
                              worksheetContainer : WorksheetEntryContainer,
                              paramSet : Map<CalcRoutineParamName,Object>)  {
    var calcRoutineDef = this.getCalcRoutine(code)
    CalcRoutine.create(calcRoutineDef).executeRoutine(this, costData, worksheetContainer, paramSet)
  }

  @Deprecated("Use executeCalcRoutine(code, costData, worksheetContainer, paramSet) instead")
  function executeCalcRoutine(code : String, costData : CostData<Cost, PolicyLine>,
                              paramSet : Map<CalcRoutineParamName,Object>) {
    executeCalcRoutine(code, costData, costData, paramSet)
  }

  static function selectRateBook(refDate : Date,
                                 baseRatingDate : Date,
                                 linePatternCode : String,
                                 jurisdiction : Jurisdiction,
                                 minimumRatingLevel : RateBookStatus,
                                 isRenewal : boolean,
                                 offeringCode : String,
                                 uwCompany : UWCompany = null) : RateBook {

    var filter = new RateBookQueryFilter(refDate, baseRatingDate, linePatternCode)
        {:MinimumRatingLevel = minimumRatingLevel,
            :RenewalJob = isRenewal,
            :Jurisdiction = jurisdiction,
            :Offering = offeringCode,
            :UWCompany = uwCompany}

    return RatingQueryFacade.matchLatestActiveRateBook(filter, RatingQueryFacade.matchers(filter))
  }

  property get Empty() : boolean {
    return not (this.RateTables.HasElements or this.RateBookCalcRoutines.HasElements)
  }

  property get RateTablesMissingInCalcRoutines(): Set<String> {
    var missingRateTableCodes: Set<String> = {}
    var rateTableCodes = this.RateTables.map(\r -> r.Definition.TableCode).toSet()

    preloadCalcRoutinesStepsOperands()

    for (routine in this.CalcRoutines) {
      var tableSteps = routine.Steps.where(\step -> step.Operands.hasMatch(\op -> op.OperandType == TC_RATETABLE))
      for (step in tableSteps) {
        for (rateTableOperand in step.Operands.where(\op -> op.OperandType == TC_RATETABLE and op.TableCode != null))
          if (!rateTableCodes.contains(rateTableOperand.TableCode)) {
            missingRateTableCodes.add(rateTableOperand.TableCode)
          }
      }
    }
    return missingRateTableCodes
  }

  function preloadCalcRoutinesStepsOperands() {
    var calcRoutineDefinitions: CalcRoutineDefinition[] = this.CalcRoutines
    var steps: CalcStepDefinition[] = calcRoutineDefinitions.arrays("Steps")
    var operands: CalcStepDefinitionOperand[] = steps.arrays("Operands")
  }

  property get LocalisedBookName(): String {
    return this["BookName_" + LocaleUtil.getDefaultLanguageType().Code] as String
  }

  /**
   * Set of Calc Routine Definitions included in this Rate Book that are not included in any promoted Rate Book.
   * Effectively, the set of Calc Routine Definitions that may need to be re-validated before this Rate Book is promoted.
   * @return Set of Calc Routine Definitions in this Rate Book that are not included in any promoted Rate Book
   */
  property get CalcRoutinesNotInPromotedRateBook(): Set<CalcRoutineDefinition> {
    var calcRoutinesInThisRateBook = Query.make(CalcRoutineDefinition)
        .withLogSQL(true)

    //Broken into a separate line otherwise it alters the type of  calcRoutinesInThisRateBook
    calcRoutinesInThisRateBook.join(RateBookCalcRoutine, "CalcRoutineDefinition")
        .compare("RateBook", Relop.Equals, this)

    var calcRoutinesInPromotedRateBooksQuery =  Query.make(CalcRoutineDefinition)
        .withLogSQL(true)

    //Broken into a separate line otherwise it alters the type of  calcRoutinesInPromotedRateBooksQuery
    calcRoutinesInPromotedRateBooksQuery
        .join(RateBookCalcRoutine, "CalcRoutineDefinition")
        .join("RateBook")
        .compare("Status", NotEquals, RateBookStatus.TC_DRAFT)

    //Both calcRoutinesInThisRateBook and calcRoutinesInPromotedRateBooksQuery are Query<CalcRoutineDefinition>
    //
    var calcRoutinesInThisBookThatAreNotAlreadyValidated = calcRoutinesInThisRateBook.subselect("ID", CompareNotIn,
        calcRoutinesInPromotedRateBooksQuery,
        "ID")

    return calcRoutinesInThisBookThatAreNotAlreadyValidated.select().toSet()
  }
}
