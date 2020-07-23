package gw.rating.flow

uses gw.entity.ITypeList
uses gw.rating.rtm.valueprovider.RateTableCellValueProviderFactory
uses gw.rating.rtm.valueprovider.TypeListValueProvider
uses gw.rating.flow.util.RateFlowReflection
uses java.lang.IllegalStateException
uses gw.rating.rtm.valueprovider.BooleanValueProvider
uses java.util.ArrayList
uses java.util.Set
uses java.util.Map
uses gw.rating.rtm.valueprovider.AbstractProductModelValueProvider
uses gw.rating.rtm.valueprovider.AbstractCovTermOptionValueProvider
uses gw.lang.reflect.IType
uses gw.rating.RateFlowLogger
uses gw.api.system.PCDependenciesGateway
uses gw.lang.reflect.TypeSystem
uses gw.api.productmodel.CoveragePattern

enhancement CalcStepDefinitionArgumentEnhancement : entity.CalcStepDefinitionArgument {

  /**
   * Examine the formal parameter (i.e. the parameter declaration) in the function or rate table,
   * and return true if the type of the parameter is a typelist.
   * @return true if formal parameter is a typelist, false otherwise.
   */
  property get ParameterTypeIsTypeList() : boolean {
    switch(this.Operand.OperandType) {
      case CalcStepOperandType.TC_RATEFUNC:
        return (getTargetParamType() typeis ITypeList)
      case CalcStepOperandType.TC_RATETABLE:
        return (ValueProvider typeis TypeListValueProvider)
           or  (ValueProvider typeis AbstractCovTermOptionValueProvider and this.AvailableTypeListValues.HasElements)
      default:
        return false
     }
  }

  /**
   * Examine the formal parameter (i.e. the parameter declaration) in the function or rate table,
   * and return true if the type of the parameter is a boolean.
   * @return true if formal parameter is a boolean, false otherwise.
   */
  property get ParameterTypeIsBoolean() : boolean {
    switch(this.Operand.OperandType) {
      case CalcStepOperandType.TC_RATEFUNC:
        return (getTargetParamType().isAssignableFrom(boolean))
      case CalcStepOperandType.TC_RATETABLE:
        return (ValueProvider typeis BooleanValueProvider)
      default:
        return false
    }
  }

  /**
   * Examine the formal parameter (i.e. the parameter declaration) in the function or rate table,
   * and return true if the type of the parameter is a date.
   * @return true if formal parameter is a boolean, false otherwise.
   */
  property get ParameterTypeIsDate() : boolean {
    switch(this.Operand.OperandType) {
      case CalcStepOperandType.TC_RATEFUNC:
        return (getTargetParamType().isAssignableFrom(java.util.Date))
      case CalcStepOperandType.TC_RATETABLE:
        var param = FirstMatchingRateTableColumn
        return param != null and param.ColumnType == TC_DATE
      default:
        return false
    }
  }

  private property get TargetParamType() : IType {
    if (this.Operand.OperandType != CalcStepOperandType.TC_RATEFUNC) {
      throw new IllegalStateException("Attemped to get property get target param type from non rate property get operand")
    }
    var matchingMethod = RateFlowReflection.getMethodInfoForMethod(this.Operand.CalcStep.CalcRoutineDefinition.PolicyLinePatternCode, this.Operand.FunctionName)
    var targetParam = matchingMethod.Parameters.singleWhere(\param -> param.Name == this.Parameter)
    return targetParam.FeatureType
  }

  property get ArgumentSourceFromTableDefs() : entity.RateTableArgumentSource {
    var matchOp = RateTableMatchOp
    if (matchOp != null and matchOp.ArgumentSources.Count > 0) {
      var argSrcSetCode = this.Operand.ArgumentSourceSetCode
      if (argSrcSetCode.HasContent) {
        return (matchOp.ArgumentSources.firstWhere(\argSrc ->argSrc.ArgumentSourceSet.Code == argSrcSetCode))
      } else {
        RateFlowLogger.Logger.warn("Rate table operand does not have an argument source set code.")
      }
    }
    return null
  }

  property get ColumnDataType(): RateTableDataType{
    return FirstMatchingRateTableColumn.ColumnType
  }

  property get CalcStepDefinition() : CalcStepDefinition {
    return this.Operand.CalcStep
  }

  property get CalcRoutineDefinition() : CalcRoutineDefinition {
    return this.Operand.CalcStep.CalcRoutineDefinition
  }

  property get RateTableMatchOp() : entity.RateTableMatchOp {
    var def = this.Operand.RateTableDefinition
    if (def == null) { // null check required for the case of a missing or renamed Rate Table
      return null
    }
   // TODO: why do we care whether they are sorted?
    return def.SortedMatchOps.firstWhere(\ matchOp -> {
      return matchOp.Name == this.Parameter
    })
  }

  property get FirstMatchingRateTableColumn() : RateTableColumn {
    var matchOp = RateTableMatchOp
    return matchOp != null ? matchOp.sortedParams().first() : null
  }

  function isEqual(other : CalcStepDefinitionArgument) : boolean {
    if(this.OperandType != other.OperandType){
      return false
    }
    switch (this.OperandType) {
      case TC_CONSTANT:
        return this.ConstantValue == other.ConstantValue
      case TC_INSCOPE:
        return (this.InScopeParam == other.InScopeParam &&
                this.InScopeValue == other.InScopeValue &&
                this.InScopeValueIsModifier == other.InScopeValueIsModifier  &&
                this.InScopeValueType == other.InScopeValueType )
      case TC_LOCALVAR:
        return this.VariableName == other.VariableName and
               this.VariableFieldName == other.VariableFieldName
      default:
        throw "Unexpected operand type"
    }
  }

  // Property for CalcStepDefinitionArgument used for display purposes.  Based on operand type, formats
  // a UI friendly string backed by a displaykey.
  property get ArgumentSource() : String {
    switch (this.OperandType) {
      case TC_CONSTANT:
        if(this.Operand.OperandType == TC_RATETABLE){
          var str : String
          var map = this.AvailableStringValues
          if(this.ConstantValue != null ) {
            str = map.get(AbstractProductModelValueProvider.removeQuotes({this.ConstantValue}).single())
            if (str != null) {
              return str
            }
          }
        }
        return this.ConstantValue== null ? null : this.StepValueDisplayName
      case TC_INSCOPE:
      case TC_LOCALVAR:
        return this.StepValueDisplayName
      default:
        return null
    }
  }

  // Only untyped constants directly set the ArgumentSource.  All other types use menu actions
  // to set argument source values.
  property set ArgumentSource(argSrcValue : String) {
    if (this.OperandType == null) {
      this.OperandType = TC_CONSTANT
      this.TypeDeclaration = null
    } else if (not this.IsEditableConstant) {
      throw new IllegalStateException("Can only set untyped constant or null argument sources")
    }
    this.LocalizedConstantValue = argSrcValue
  }

  property get ArgumentValueForDependency() : String {
    switch (this.OperandType) {
      case TC_CONSTANT:
        if (this.IsDate) {
         return this.DateConstantValue.ShortFormat
        } else if (this.IsTypeKey) {
         return this.TypekeyConstantValue.Code
        }
        return this.ConstantValue

      case TC_LOCALVAR: // can process localvar provided InScopeValueType is correctly set.
      case TC_INSCOPE:
        if (this.InScopeValueType == null) {
          return ""
        }

        // NOTE: it would be nicer if we had the InScopeUsage, from which we can
        // figure out whether the value has a string that can be used to satisfy a
        // dependency (e.g. it's a Coverage or CovTerm)

        var iType = TypeSystem.getByFullName(this.InScopeValueType)
        var lastDot = this.InScopeValueType.lastIndexOf(".")

        // Coverage and CovTerm dependencies
        if (this.isCoverageType(iType)) {
          if (this.InScopeValue == null) {
            // root value -- use pattern code from the parameter
            return this.CalcRoutineDefinition.ParameterSet.Parameters.singleWhere(\ p -> p.Code == this.InScopeParam).CoveragePattern
          }

          // get the code identifier, and translate it to a CoveragePattern's PublicID
          var codeIdentifier = this.InScopeValueType.substring(lastDot + 1)
          var publicID = PCDependenciesGateway.getProductModel().getPublicIdForCodeIdentifier(codeIdentifier, CoveragePattern)
          if (publicID != null) {
            return publicID
          }
        } else if (this.CovTermCode != null and this.isCovTermType(iType)) {
          return this.CovTermCode
        }

        return "" // can't figure it out...don't accidentally match a dependency

      default:
        return "" // can't figure it out...don't accidentally match a dependency
    }
  }

  property get AvailableTypeListValues() : List<gw.entity.TypeKey> {
    if (ValueProvider typeis TypeListValueProvider) {
      return ValueProvider.getTypelistValues()
    } else {
      var param = FirstMatchingRateTableColumn
      var alist = new ArrayList<RateTableColumn> ()
      var depList = getDependencyList(param, alist)
      if (!depList.Empty) {
        return ValueProvider.getDependentValuesAsTypeKeys(getDependencyStringList(depList).toTypedArray())
      }
    }
    return {}
  }

  property get DependentList(): List<RateTableColumn> {
    var allDependents : Set<RateTableColumn> = {}

    // recursive traversal, because in this direction dependents can form a tree.
    var checkDependents : block(cols : List<RateTableColumn>)
    checkDependents = \ cols -> {
      var newCols = cols.where(\ c -> not allDependents.contains(c))
      newCols.each(\ c -> {
        allDependents.add(c)
        checkDependents(c.Dependents)
      })
    }

    checkDependents(FirstMatchingRateTableColumn.Dependents)
    return allDependents.toList()
  }

  function getDependencyList(param : entity.RateTableColumn, alist : ArrayList<RateTableColumn>) : List<RateTableColumn> {
    // todo: when traversing up, we could iterate.
    if (param.DependsOn == null) {
      return (alist == null) ? {} : alist.reverse()
    }
    alist.add(param.DependsOn)
    return getDependencyList(param.DependsOn, alist)
  }

  property get HasDependency() : boolean {
    return FirstMatchingRateTableColumn.DependsOn != null
  }

  property get HasDependent() : boolean {
    return FirstMatchingRateTableColumn.HasDependent
  }

  private function valueProviderForParam(param : entity.RateTableColumn) : gw.rating.rtm.valueprovider.RateTableCellValueProvider {
    if (RateTableMatchOp == null) {
      return null
    }
    if (RateTableMatchOp.isIncompleteTypeListValueProvider(param)) {
      return null
    }
    return RateTableCellValueProviderFactory.getValueProvider(param)
  }

  protected property get ValueProvider() : gw.rating.rtm.valueprovider.RateTableCellValueProvider {
    return valueProviderForParam(FirstMatchingRateTableColumn)
  }

  property get AvailableStringValues() : Map<String, String> {
    var param = FirstMatchingRateTableColumn
    var alist = new ArrayList<RateTableColumn> ()
    var depList = getDependencyList(param, alist)
    var provider = ValueProvider

    if (provider == null) {
      return {}
    }

    if (provider typeis TypeListValueProvider) {
      return {}
    } else if (!depList.Empty) {
      var strList = getDependencyStringList(depList)
      return provider.getDependentValues(strList.toTypedArray())
    }

    var s = provider.getValues(null)
    var m : Map<String, String> = {}
    s.each(\ code -> m.put(code, provider.valueByCode(null, code)))
    return m
  }

  function getDependencyStringList(depList :java.util.List<entity.RateTableColumn>) : List<String> {
    var strList = new ArrayList<String> ()

    // if there are arguments, prepend them.
    // NOTE: Right now this is here for the case where there is a CovTerm provider with one argument,
    // and a CovTermOption that depends on it.
    //
    // In the case that someone builds a longer dependency chain, this has to do something more
    // sophisticated... but we don't currently have the ability to query value providers about
    // how many dependencies they need.
    var firstProvider = valueProviderForParam(depList.first())
    if (firstProvider.Arguments.HasElements) {
      strList.add(firstProvider.Arguments.first())
    }

    depList.each(\ dl -> {
      var argSource =  this.Operand.ArgumentSources.singleWhere(\ c -> c.Parameter == dl.MatchOp.Name)
      var valueDependsOn = (argSource.OverrideSource)? argSource.ArgumentValueForDependency : argSource.ArgumentSourceFromTableDefs.ArgumentSource
      if (valueDependsOn != null) {
         strList.add(valueDependsOn)
       }
    })
    return AbstractProductModelValueProvider.removeQuotes(strList.toTypedArray()).toList()
  }

  function clear() {
    this.OperandType = null
    this.clearValueDelegateValues()
    this.OverrideSource = false
  }

  property get PossibleTypes() : Set<IType> {
    var paramTypes : Set<IType> = {}
    switch (this.Operand.OperandType) {
      case TC_RATEFUNC:
          paramTypes.add(RateFlowReflection.getFunctionParameterType(this.CalcRoutineDefinition.PolicyLinePatternCode,
              this.Operand.FunctionName,
              this.Parameter))
          break
      case TC_RATETABLE:
          if (this.OverrideSource) {
            var typeSet = RateFlowReflection.getTableParameterTypes(this)
            if (typeSet != null) {
              paramTypes.addAll(typeSet)
            }
          }
          break
        default:
    }
    return paramTypes
  }
}
