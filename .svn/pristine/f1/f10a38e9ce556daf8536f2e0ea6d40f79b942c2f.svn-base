package gw.rating.rtm

uses gw.api.database.Query
uses gw.api.util.LocaleUtil
uses gw.lang.reflect.IType
uses gw.lang.reflect.TypeSystem
uses gw.pcf.rating.flow.RateRoutineRateTablePopupHelper
uses gw.pcf.rating.rtm.RateTableParameterSetHelper
uses gw.rating.flow.MultiFactorVariable
uses gw.rating.rtm.query.RateQueryParam

uses java.lang.Integer
uses java.math.BigDecimal
uses java.util.ArrayList
uses java.util.Date
uses java.util.Map

enhancement RateTableDefinitionEnhancement : entity.RateTableDefinition {

  private static property get TYPEMAP () : Map<RateTableDataType, Type> {
    return {
      RateTableDataType.TC_STRING   -> String,
      RateTableDataType.TC_INTEGER  -> Integer,
      RateTableDataType.TC_DECIMAL  -> BigDecimal,
      RateTableDataType.TC_DATE     -> Date,
      RateTableDataType.TC_BOOLEAN  -> Boolean
    }
  }


  property get AllColumns() : RateTableColumn[] {
    return SortedParameters.concat(SortedFactors)
  }

  property get SortedParameters() : RateTableColumn[] {
    return this.MatchOps*.Params.orderBy(\ col -> col.SortOrder ?: 0).toTypedArray()

    // The following line works in theory, but is causing problems due to what appears to be a platform
    //   bug when BeanProxy#isBeanChanged() is called from RateTableMatchOpImpl#sortedParams(). If
    //   this gets fixed, the line below should be faster than the one above.
    //
    // return this.SortedMatchOpArray.flatMap(\ mo -> mo.sortedParams())
  }

  property get SortedFactors() : RateTableColumn[] {
    return this.Factors.orderBy(\ col -> (col.SortOrder == null) ? 0 : col.SortOrder).toTypedArray()
  }

  function getFactorPhysicalColumnName() : String {
    return getFactorPhysicalColumnName(null)
  }

  function getFactorPhysicalColumnName(factorName : String) : String {
    if (factorName.length > 0) {
      var factor = this.Factors.firstWhere(\rtc -> rtc.ColumnName == factorName).PhysicalColumnName
      if (factor == null) {
        throw new gw.api.util.DisplayableException(displaykey.Web.Rating.RateTableDefinition.FactorNotFound(factorName, this.TableCode))
      }
      return factor
    } else {
      return this.Factors.single().PhysicalColumnName
    }
  }

  function getFactorIType(factorName : String) : IType {
    if (factorName == RateRoutineRateTablePopupHelper.AllFactorsCode) {
      return MultiFactorVariable
    } else {
      var rtDataType = this.Factors.singleWhere(\f -> f.ColumnName == factorName).ColumnType
      return TYPEMAP.get(rtDataType)
    }
  }

  function getFactorLabel(factorColumnName : String) : String {
    return this.Factors
      .where(\f -> f.ColumnName == factorColumnName)
      .single().ColumnLabel
  }

  function getMatchOpFor(inputParam : RateQueryParam) : RateTableMatchOp {
    return this.MatchOps.firstWhere(\ ops -> ops.hasSameNameAs(inputParam))
  }

  /*
   * Validates and returns the custom entity type specified in the rate table definition.
   * Returns default entity type if custom entity name is not defined in
   * the rate table definition.
   * For custom entity types, checks its existance in the type system and existance of the
   * RateTable foreign key that points to rate table definition.
   */
  property get FactorRowEntity() : IType {
    if (not hasValidEntity()) {
      throw new InvalidCustomRateTableException(displaykey.Web.Rating.Errors.CustomEntityDoesNotExist(this.EntityName))
    }
    return getEntityTypeClass()
  }

  property get QualifiedEntityName() : String {

    return "entity.${this.EntityName}"
  }

  function hasValidEntity() : boolean {
    var type = getEntityTypeClass()
    if (type == null) return false

    var prop = type.TypeInfo.getProperty("RateTable")
    if (prop == null or prop.FeatureType != RateTable) {
      return false
    }
    return true
  }

  property get UsedInPromotedRateBook(): boolean {
    return this.IsInPromotedRateBookViaRateRoutine
        or this.IsInPromotedRateBookViaRateTable
  }

  property get IsInPromotedRateBookViaRateTable(): boolean {
    return this.tablesUsingDefinition().hasMatch(\elt -> !elt.RateBook.isDraft())
  }

  function tablesUsingDefinition() : List<RateTable> {
    return gw.api.database.Query.make(RateTable).compare("Definition", Equals, this).select().toList()
  }

  /**
   * Determines if rate routines used in promoted books are using the specified parameter.
   * A rate routine is "using" a parameter if the routine
   * performs a rate table lookup that requires the parameter.
   */
  function isParamUsedInRateRoutineInPromotedRB(param: RateTableColumn) : boolean {
    return this.getRoutinesUsingParam(param).where(\elt -> elt.isIncludedInPromotedRateBook()).HasElements
  }

  /**
   * Determines if rate routines used in promoted books are using the specified parameter.
   * A rate routine is "using" a parameter if the routine
   * performs a rate table lookup that requires the parameter.
   */
  function isFactorUsedInRateRoutineInPromotedRB(factor: RateTableColumn): boolean {
    return this.getRoutinesUsingFactor(factor).where(\elt -> elt.isIncludedInPromotedRateBook()).HasElements
  }

  function getRoutinesUsingFactor(factor: RateTableColumn): List<CalcRoutineDefinition> {
    return Query.make(CalcRoutineDefinition)
        .join(CalcStepDefinition, "CalcRoutineDefinition")
        .join(CalcStepDefinitionOperand, "CalcStep")
        .compare("TableCode", Equals, this.TableCode)
        .join(CalcStepDefinitionRateFactor, "Operand")
        .compare("ColumnName", Equals, factor.DisplayName)
        .withDistinct(true)
        .select()
        .toList()
  }

  /**
   * Determines if any rate routines are using the specified parameter.
   * A rate routine is "using" a parameter if the routine
   * performs a rate table lookup that requires the parameter.
   */
  function isParamUsedInAnyRateRoutine(param: RateTableColumn): boolean {
    return !this.getRoutinesUsingParam(param).Empty
  }

  function getRoutinesUsingParam(param: RateTableColumn): List<CalcRoutineDefinition> {
    var paramCode = param.DisplayName
    return Query.make(CalcRoutineDefinition)
        .join(CalcStepDefinition, "CalcRoutineDefinition")
        .join(CalcStepDefinitionOperand, "CalcStep")
        .compare("TableCode", Equals, this.TableCode)
        .join(CalcStepDefinitionArgument, "Operand")
        .compare("Parameter", Equals, paramCode)
        .withDistinct(true)
        .select()
        .toList()
  }

  /**
   * Determines if any rate routines are using the specified parameter.
   * A rate routine is "using" a parameter if the routine
   * performs a rate table lookup that requires the parameter.
   */
  function isFactorUsedInAnyRateRoutine(factor: RateTableColumn): boolean {
    return !this.getRoutinesUsingFactor(factor).Empty
  }

  /**
   * Determines if the specified factor is used in any rate table.
   * A rate table is "using" a parameter if its column has at least one non-null entry.
   */
  function isFactorUsedInAnyRateTable(factor: RateTableColumn): boolean {
    return isParameterUsedInAnyRateTable(factor)
  }

  /**
   * Determines if the specified factor is used in a promoted rate table.
   * A rate table is "using" a factor if its column has at least one non-null entry.
   */
  function isFactorUsedInPromotedRateTable(factor: RateTableColumn): boolean {
    return this.isParameterUsedInPromotedRateTable(factor)
  }

  /**
   * Determines if the specified parameter is used in a promoted rate table.
   * A rate table is "using" a parameter if its column has at least one non-null entry.
   */
  function isParameterUsedInPromotedRateTable(param: RateTableColumn): boolean {
    var tablesUsingDefinition = tablesUsingDefinition().where(\elt -> !elt.RateBook.isDraft())
    var physicalColumnName = param.PhysicalColumnName

    if (physicalColumnName == null) {
      return false
    }

    for (table in tablesUsingDefinition) {
      var rowsUsingParam = Query.make(table.Definition.FactorRowEntity)
          .compare("RateTable", Equals, table.TableOwningFactors)
          .compare(physicalColumnName, NotEquals, null)
          .select()
      if (not rowsUsingParam.Empty) {
        return true
      }
    }

    return false
  }

  /**
   * Determines if the specified parameter is used in any rate table.
   * A rate table is "using" a parameter if its column has at least one non-null entry.
   */
  function isParameterUsedInAnyRateTable(param : RateTableColumn) : boolean {
    var tablesUsingDefinition = tablesUsingDefinition()
    var physicalColumnName = param.PhysicalColumnName

    if (physicalColumnName == null) {
      return false
    }

    for (table in tablesUsingDefinition) {
      var rowsUsingParam = Query.make(table.Definition.FactorRowEntity)
          .compare("RateTable", Equals, table.TableOwningFactors)
          .compare(physicalColumnName, NotEquals, null)
          .select()
      if (not rowsUsingParam.Empty) {
        return true
      }
    }

    return false
  }

  property get ReferencingRateRoutines() : List<CalcRoutineDefinition> {
    return Query.make(CalcRoutineDefinition)
        .join(CalcStepDefinition, "CalcRoutineDefinition")
        .join(CalcStepDefinitionOperand, "CalcStep")
        .compare("TableCode", Equals, this.TableCode)
        .select()
        .toList()
  }

  property get IsInPromotedRateBookViaRateRoutine() : boolean {
    return this.ReferencingRateRoutines.hasMatch( \ elt -> elt.isIncludedInPromotedRateBook())
  }

  function delete(){
    using(new java.util.concurrent.locks.ReentrantLock()){
      if(tablesUsingDefinition().Empty){
        this.Bundle.delete(this)
        this.Bundle.commit()
      }
      else{
        throw new gw.api.util.DisplayableException(displaykey.Web.Rating.RateTableDefinition.CannotDelete)
      }
    }
  }

  private function getEntityTypeClass() : IType {
    return TypeSystem.getByFullNameIfValid(this.QualifiedEntityName)
  }

  function availablePhysicalColumnsForDataType(dataType : typekey.RateTableDataType) : List<String> {
    var columnsForType: List<String>

    var allProperties = (FactorRowEntity as Type<KeyableBean>).EntityProperties.toList()
      .where(\ ep -> ep.ColumnInDb and not ep.Autogenerated)
    var propsByType = allProperties.partition(\ p -> p.FeatureType)
    var propsForType = propsByType.get(TYPEMAP.get(dataType))
    if (propsForType == null) {
      columnsForType = new ArrayList<String>()
    } else {
      columnsForType = propsForType*.Name.toList()
    }
    var allInUse = this.AllColumns*.PhysicalColumnName
    columnsForType.removeWhere(\ c -> allInUse.contains(c))

    return columnsForType
  }

  function resetPhysicalColumnNames() {
    this.AllColumns.each(\ col -> { col.PhysicalColumnName = "" })
  }

  function initializeCopy() : RateTableDefinition {
    var copiedTableDefinition : RateTableDefinition
    copiedTableDefinition = this.copy() as RateTableDefinition

    //Using AutoMap to allow adding things to the list without having to check for null
    var matchOpNamesMappedToCopiedArgumentSources : Map<String, List<RateTableArgumentSource>>
      = {}.toAutoMap(\ s -> new ArrayList<RateTableArgumentSource>())

    copiedTableDefinition.ArgumentSourceSets.each(\ copiedArgSrcSet -> {
      copiedArgSrcSet.RateTableArgumentSources.each(\ copiedArgSrc -> {
        var copiedArgSrcs = matchOpNamesMappedToCopiedArgumentSources.get(copiedArgSrc.Parameter.Name)
        //The use of AutoMap allows calling "add" on this List without first checking if it is null
        copiedArgSrcs.add(copiedArgSrc)
      })
    })

    copiedTableDefinition.MatchOps.each(\ copiedMatchOp -> {
      var copiedArgSrcs = matchOpNamesMappedToCopiedArgumentSources.get(copiedMatchOp.Name)
      // Use of AutoMap allows calling "each" on this list without first checking if it is null
      copiedArgSrcs.each(\ copiedArgSrc -> copiedMatchOp.addToArgumentSources(copiedArgSrc))
    })

    copiedTableDefinition.TableCode = null
    copiedTableDefinition.TableName = displaykey.Web.Rating.RateTableDefinition.CopyPrefix(this.TableName)

    for (column in copiedTableDefinition.AllColumns) {
      //change all columns to point to the new rate table definition
      column.Definition = copiedTableDefinition
      //change all parameters that depend on another column to point to the columns in the new table definition
      if (column.IsParameterColumn and column.DependsOn != null) {
        column.DependsOn = copiedTableDefinition.SortedParameters.firstWhere(\ p -> p.ColumnName == column.DependsOn.ColumnName)
      }
    }
    return copiedTableDefinition
  }

  function isEqual(other : RateTableDefinition) : boolean {
    if (this.EntityName != other.EntityName) return false
    if (this.PolicyLine != other.PolicyLine) return false
    if (this.TableCode != other.TableCode) return false
    if (this.MatchOps.Count != other.MatchOps.Count) return false
    if (this.Factors.Count != other.Factors.Count) return false

    return sameMatchOpsAs(other) and sameFactorsAs(other)
  }

  private function sameFactorsAs(other : RateTableDefinition) : boolean {
    var same : boolean = true
    this.Factors.eachWithIndex(\ f, i -> {
      if (!f.isEqual(other.Factors[i])) {
        same = false
      }
    })
    return same
  }

  private function sameMatchOpsAs(other : RateTableDefinition) : boolean {
    var same : boolean = true
    this.MatchOps.eachWithIndex(\ op, i -> {
      if (!op.isEqual(other.MatchOps[i])) {
        same = false
      }
    })
    return same
  }

  function getParameterSet() : CalcRoutineParameterSet {
    if (this.ArgumentSourceSets.Count > 0) {
      return this.ArgumentSourceSets.first().CalcRoutineParameterSet
    } else {
      return null
    }
  }

  function setParameterSet(paramSet : CalcRoutineParameterSet) {
    var sets = this.ArgumentSourceSets
    sets.each(\argSrcSet -> {
      this.removeFromArgumentSourceSets(argSrcSet)
    })
    // PC-15668: do we really want to clear out everything here, or should
    // we try to retain anything that could carry over from one param set to another?
    for (op in this.MatchOps) {
      for (argumentSource in op.ArgumentSources) {
        argumentSource.remove()
      }
    }
    if (paramSet != null) {
      var helper = new RateTableParameterSetHelper(this)
      var defaultArgSrcSet = helper.addNewArgumentSourceSet(paramSet)
    }
  }

  function getArgumentSourceSet(code : String) : RateTableArgumentSourceSet {
    return this.ArgumentSourceSets.firstWhere(\argSrcSet -> argSrcSet.Code == code)
  }

  property get LocalizedTableName(): String {
    return this["TableName_" + LocaleUtil.getDefaultLanguageType().Code] as String
  }

  property get LocalizedTableDesc(): String {
    return this["TableDesc_" + LocaleUtil.getDefaultLanguageType().Code] as String
  }
}
