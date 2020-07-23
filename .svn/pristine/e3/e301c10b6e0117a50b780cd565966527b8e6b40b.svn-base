package gw.sampledata.tiny

uses gw.api.database.Query
uses gw.lob.pa.rating.DriverAssignmentInfo
uses gw.rating.flow.builders.CalcRoutineParameterBuilder
uses gw.rating.flow.builders.CalcRoutineParameterSetBuilder
uses gw.sampledata.AbstractSampleDataCollection
uses java.lang.IllegalStateException
uses gw.lob.cp.rating.CPCoverageWrapper

@Export
class TinySampleRatingData extends AbstractSampleDataCollection
{
  construct() { }

  /**
   * The name of this sample data collection, for logging and debugging
   */
  public override property get CollectionName() : String {
    return "Tiny Rating"
  }

  override property get AlreadyLoaded() : boolean {
    return parameterSetLoaded("PACoverageParamSet") and parameterSetLoaded("CPCoverageParamSet") and parameterSetLoaded("GenericStateTaxParamSet")
  }

  override function load() {
    if (not parameterSetLoaded("CPCoverageWrapperParamSet")) {
      loadCPParameterSets() 
    }
    if (not parameterSetLoaded("PACoverageParamSet")) {
      loadPAParameterSets()
    }
    if (not parameterSetLoaded("GenericStateTaxParamSet")) {
      loadStateTaxParamSet()
    }
  }
  
  private function loadPAParameterSets() {
    new CalcRoutineParameterSetBuilder()
      .withPublicId("pc:TSRD:ParamSet01")
      .withCode("PACoverageParamSet")
      .withName(displaykey.Web.Rating.ParameterSets.PACoverage)
      .withPolicyLinePatternCode("PersonalAutoLine")
      .withParameter(
        new CalcRoutineParameterBuilder()
          .withCode("policyline")
          .withParamType(entity.PersonalAutoLine)
          .withPublicId("pc:TSRD:Param001")
        )
      .withParameter(
        new CalcRoutineParameterBuilder()
          .withCode("coverage")
          .withParamType(entity.Coverage)
          .withPublicId("pc:TSRD:Param002")
        )
      .withParameter(
        new CalcRoutineParameterBuilder()
          .withCode("vehicle")
          .withParamType(entity.PersonalVehicle)
          .withPublicId("pc:TSRD:Param003")
        )
        .createAndCommit()
        verifyLoaded("PACoverageParamSet")

    new CalcRoutineParameterSetBuilder()
      .withPublicId("pc:TSRD:ParamSet02")
      .withCode("StateTaxParamSet")
      .withName(displaykey.Web.Rating.ParameterSets.PAStateTax)
      .withPolicyLinePatternCode("PersonalAutoLine")
      .withParameter(
        new CalcRoutineParameterBuilder()
          .withCode("policyline")
          .withParamType(entity.PolicyLine)
          .withPublicId("pc:TSRD:Param004")
        )
      .withParameter(
        new CalcRoutineParameterBuilder()
          .withCode("taxablebasis")
          .withParamType(java.math.BigDecimal)
          .withPublicId("pc:TSRD:Param005")
        )
        .createAndCommit()
        verifyLoaded("StateTaxParamSet")

    new CalcRoutineParameterSetBuilder()
      .withPublicId("pc:TSRD:ParamSet03")
      .withCode("PIPNJParamSet")
      .withName(displaykey.Web.Rating.ParameterSets.PIPNJ)
      .withPolicyLinePatternCode("PersonalAutoLine")
      .withParameter(
        new CalcRoutineParameterBuilder()
          .withCode("papipnj")
          .withParamType(entity.Coverage)
          .withCoverageCode("PAPIP_NJ")
          .withPublicId("pc:TSRD:Param006")
        )
      .withParameter(
        new CalcRoutineParameterBuilder()
          .withCode("policyline")
          .withParamType(entity.PersonalAutoLine)
          .withPublicId("pc:TSRD:Param007")
        )
      .withParameter(
        new CalcRoutineParameterBuilder()
          .withCode("vehicle")
          .withParamType(entity.PersonalVehicle)
          .withPublicId("pc:TSRD:Param008")
        )
        .createAndCommit()
        verifyLoaded("PIPNJParamSet")

    new CalcRoutineParameterSetBuilder()
      .withPublicId("pc:TSRD:ParamSet05")
      .withCode("PAVehicleCoverageParamSet")
      .withName(displaykey.Web.Rating.ParameterSets.PAVehicleCoverage)
      .withPolicyLinePatternCode("PersonalAutoLine")
      .withParameter(
        new CalcRoutineParameterBuilder()
          .withCode("policyline")
          .withParamType(entity.PersonalAutoLine)
          .withPublicId("pc:TSRD:Param012")
        )
      .withParameter(
        new CalcRoutineParameterBuilder()
          .withCode("coverage")
          .withParamType(entity.Coverage)
          .withPublicId("pc:TSRD:Param013")
        )
      .withParameter(
        new CalcRoutineParameterBuilder()
          .withCode("vehicle")
          .withParamType(entity.PersonalVehicle)
          .withPublicId("pc:TSRD:Param014")
        )
      .withParameter(
        new CalcRoutineParameterBuilder()
          .withCode("assigneddriver")
          .withParamType(entity.VehicleDriver)
          .withPublicId("pc:TSRD:Param015")
        )
      .withParameter(
        new CalcRoutineParameterBuilder()
          .withCode("previoustermamount")
          .withParamType(java.math.BigDecimal)
          .withPublicId("pc:TSRD:Param016")
        )
      .createAndCommit()
      verifyLoaded("PAVehicleCoverageParamSet")
      
    new CalcRoutineParameterSetBuilder()
      .withPublicId("pc:TSRD:ParamSet06")
      .withCode("PADriverAssignmentParamSet")
      .isNonCost()
      .withName(displaykey.Web.Rating.ParameterSets.PADriverAssignment)
      .withPolicyLinePatternCode("PersonalAutoLine")
      .withParameter(
        new CalcRoutineParameterBuilder()
          .withCode("policyline")
          .withParamType(entity.PersonalAutoLine)
          .withPublicId("pc:TSRD:Param017")
        )
      .withParameter(
        new CalcRoutineParameterBuilder()
          .withCode("driverassignmentinfo")
          .withParamType(DriverAssignmentInfo)
          .isWritable()
          .withPublicId("pc:TSRD:Param018")
        )
      .withParameter(
        new CalcRoutineParameterBuilder()
          .withCode("currentdriver")
          .withParamType(entity.VehicleDriver)
          .withPublicId("pc:TSRD:Param019")
        )
      .withParameter(
        new CalcRoutineParameterBuilder()
          .withCode("vehicle")
          .withParamType(entity.PersonalVehicle)
          .withPublicId("pc:TSRD:Param020")
        )
     .createAndCommit()
      verifyLoaded("PADriverAssignmentParamSet")
  
    new CalcRoutineParameterSetBuilder()
      .withPublicId("pc:TSRD:ParamSet07")
      .withCode("PACancellationShortRatePenaltyParamSet")
      .withName(displaykey.Web.Rating.ParameterSets.PACancellationShortPenaltyParamSet)
      .withPolicyLinePatternCode("PersonalAutoLine")
      .withParameter(
        new CalcRoutineParameterBuilder()
          .withCode("policyline")
          .withParamType(entity.PersonalAutoLine)
          .withPublicId("pc:TSRD:Param021")
        )
      .withParameter(
        new CalcRoutineParameterBuilder()
          .withCode("proratedpremiumtotal")
          .withParamType(java.math.BigDecimal)
          .withPublicId("pc:TSRD:Param022")
        )
        .createAndCommit()
        verifyLoaded("PACancellationShortRatePenaltyParamSet")
  }

  private function loadCPParameterSets() {
    new CalcRoutineParameterSetBuilder()
        .withPublicId("pc:TSRD:CPSet01")
        .withCode("CPStateTaxParamSet")
        .withName(displaykey.Web.Rating.ParameterSets.CPStateTax)
        .withPolicyLinePatternCode("CPLine")
        .withParameter(
        new CalcRoutineParameterBuilder()
            .withCode("policyline")
            .withParamType(entity.PolicyLine)
            .withPublicId("pc:TSRD:CPParam001")
    )
        .withParameter(
        new CalcRoutineParameterBuilder()
            .withCode("taxablebasis")
            .withParamType(java.math.BigDecimal)
            .withPublicId("pc:TSRD:CPParam002")
    )
        .withParameter(
        new CalcRoutineParameterBuilder()
            .withCode("state")
            .withParamType(typekey.Jurisdiction)
            .withPublicId("pc:TSRD:CPParam003")
    )
        .createAndCommit()
    verifyLoaded("CPStateTaxParamSet")

    new CalcRoutineParameterSetBuilder()
        .withPublicId("pc:TSRD:CPSet02")
        .withCode("CPCoverageWrapperParamSet")
        .withName(displaykey.Web.Rating.ParameterSets.CPCoverageWrapper)
        .withPolicyLinePatternCode("CPLine")
        .withParameter(
        new CalcRoutineParameterBuilder()
            .withCode("coverage")
            .withParamType(entity.Coverage)
            .withCoverageWrapper(CPCoverageWrapper)
            .withPublicId("pc:TSRD:CPParam004")
    )
        .withParameter(
        new CalcRoutineParameterBuilder()
            .withCode("building")
            .withParamType(entity.CPBuilding)
            .withPublicId("pc:TSRD:CPParam005")
    )
        .withParameter(
        new CalcRoutineParameterBuilder()
            .withCode("policyline")
            .withParamType(entity.CommercialPropertyLine)
            .withPublicId("pc:TSRD:CPParam006")
    )
        .withParameter(
        new CalcRoutineParameterBuilder()
            .withCode("cpdeductfactorname")
            .withParamType(java.lang.String)
            .withPublicId("pc:TSRD:CPParam007")
    )
        .createAndCommit()
    verifyLoaded("CPCoverageWrapperParamSet")
  }

  private function loadStateTaxParamSet() {
    new CalcRoutineParameterSetBuilder()
      .withPublicId("pc:TSRD:TaxParamSet01")
      .withCode("GenericStateTaxParamSet")
      .withName(displaykey.Web.Rating.ParameterSets.StateTax)
      .withParameter(
        new CalcRoutineParameterBuilder()
            .withCode("policyline")
            .withParamType(entity.PolicyLine)
            .withPublicId("pc:TSRD:TaxParam001")
        )
      .withParameter(
        new CalcRoutineParameterBuilder()
          .withCode("taxablebasis")
          .withParamType(java.math.BigDecimal)
          .withPublicId("pc:TSRD:TaxParam002")
        )
      .withParameter(
        new CalcRoutineParameterBuilder()
          .withCode("state")
          .withParamType(typekey.Jurisdiction)
          .withPublicId("pc:TSRD:TaxParam003")
        )
      .createAndCommit()
    verifyLoaded("GenericStateTaxParamSet")
  }

  private function verifyLoaded(paramSetCode : String) {
    var paramSet = queryParameterSet(paramSetCode).single()
    if (paramSet == null) {
      throw new IllegalStateException("Should have loaded '${paramSet}'.")
    }
  }
    
  private function parameterSetLoaded(paramSetCode : String) : boolean {
    return not (queryParameterSet(paramSetCode).Empty)
  }
  
  private function queryParameterSet(paramSetCode : String) : gw.api.database.IQueryBeanResult<entity.CalcRoutineParameterSet> {
    return Query<CalcRoutineParameterSet>.make(CalcRoutineParameterSet).compare("Code", Equals, paramSetCode).select()
  }

}
