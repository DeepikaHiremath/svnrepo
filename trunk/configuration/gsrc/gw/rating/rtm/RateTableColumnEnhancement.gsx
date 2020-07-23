package gw.rating.rtm

uses gw.api.database.Query
uses gw.api.util.LocaleUtil
uses gw.rating.rtm.domain.table.RateTableCell

uses java.util.ArrayList

enhancement RateTableColumnEnhancement : entity.RateTableColumn {

  public static property get MULTI_VALUE_SEPARATOR() : String  { return "," }

  public static function unpackMultiSelectString(packedString : String) : List<String> {
    var result = new ArrayList<String>()
    if (packedString == null) return result
    var split = packedString.split(MULTI_VALUE_SEPARATOR)
    for (value in split) {
      var cleanValue = value.trim()
      if (!cleanValue.equals("")) {
        result.add(cleanValue)
      }
    }
    return result
  }

  public static function packMultiSelectValues(valuesToPack : List<String>) : String {
    if (valuesToPack.Empty) return ""
    if (valuesToPack.size() ==  1) return valuesToPack.first()
    return MULTI_VALUE_SEPARATOR +
        valuesToPack.join(MULTI_VALUE_SEPARATOR) +
        MULTI_VALUE_SEPARATOR
  }

  property get Definition() : RateTableDefinition {
    if (this.DefinitionForParam != null) return this.DefinitionForParam
    else if (this.DefinitionForFactor != null) return this.DefinitionForFactor
    return null
  }

  property set Definition(rtDef : RateTableDefinition)  {
    if (this.DefinitionForParam != null){
      this.DefinitionForParam = rtDef
    }
    else if (this.DefinitionForFactor != null){
      this.DefinitionForFactor = rtDef
    }
  }

  property get HasDependent() : Boolean {
    return not Dependents.Empty
  }

  property get Dependents() : List<RateTableColumn> {
    return Query.make(RateTableColumn).compare("DependsOn", Equals, this.ID).select().toList()
  }

  property get HasValueProvider() : Boolean {
    return this.ValueProvider.HasContent or this.ColumnType == RateTableDataType.TC_BOOLEAN
  }

  property get IsFactorColumn() : boolean {
    return this.DefinitionForFactor != null
  }

  property get IsParameterColumn() : boolean {
    return this.DefinitionForParam != null
  }

  property get CustomValProviderClass(): ValueProvider {
    var providerType: ValueProvider
    if(this.ValueProvider != null and this.ValueProvider.NotBlank){
      var p = gw.rating.rtm.valueprovider.Parser.parse(this.ValueProvider)
      var keyValue = p.ClassName.substring("gw.rating.rtm.valueprovider.".length)
      providerType = ValueProvider.get(keyValue)
    }
    return providerType
  }

  property set CustomValProviderClass(className: ValueProvider){
    if(className != null){
      this.ValueProvider = "gw.rating.rtm.valueprovider." + className.Code
    }
  }

  function clearArgumentSources() {
    if (this.MatchOp != null) { //will be null for factor columns
      this.MatchOp.ArgumentSources.each(\ asrc -> {
        asrc.Root = null
        asrc.ArgumentSource = null
      })
    }
  }

  function isEqual(other : RateTableColumn) : boolean {
    return (this.ColumnName == other.ColumnName) and
           (this.ColumnType == other.ColumnType) and
           (this.PhysicalColumnName == other.PhysicalColumnName) and
           (this.SortOrder == other.SortOrder) and
           (this.DependsOn.PublicID == other.DependsOn.PublicID) and
           (this.ValueProvider == other.ValueProvider)
  }

  property get Scale() : int {
    return scale(this.PhysicalColumnName)
  }

  property get Precision() : int {
    return precision(this.PhysicalColumnName)
  }

  function scale(colName : String) : int {
    return Definition.getColumnScale(colName) ?: RateTableCell.FACTOR_SCALE
  }

  function precision(colName : String) : int {
    return Definition.getColumnPrecision(colName) ?: RateTableCell.FACTOR_PRECISION
  }

  property get EditMode() : String {
    return getEditModeByLocationEditMode(true)
  }

  function getEditModeByLocationEditMode(locationInEditMode : boolean) : String {
    if (this.ColumnType == typekey.RateTableDataType.TC_DATE) {
      return "date"
    } else if (this.HasValueProvider) {
      if (this.MultiSelect) {
        return locationInEditMode ? "multiselect" : "multiselect_readonly"
      }
      return this.HasDependent ? "selectwithrefresh" : "select"
    } else switch (this.DisplayType) {
      case TC_SMALL:  return "small"
      case TC_LARGE:  return "large"
      case TC_NORMAL:
      default: return "default"
    }
  }

  property get LocalizedColumnLabel(): String {
    return this["ColumnLabel_" + LocaleUtil.getDefaultLanguageType().Code] as String
  }
}
