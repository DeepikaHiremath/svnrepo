package gw.rating.rtm

uses java.util.ArrayList

enhancement CalcRoutineParameterCollectionEnhancement : List<CalcRoutineParameter> {

  property get ParameterSetForUIMessage() : String {
    var changedParameters = new ArrayList<String>()
    this.partition( \ elt -> elt.Code).eachKeyAndValue( \ k, val -> {
      var parametersByCode = k + " (" + val*.ParamType.join(displaykey.Web.Rating.Parameter.Delimiter) + ")"
      changedParameters.add(parametersByCode)
    })

    return changedParameters.join(displaykey.Web.Rating.Parameter.Delimiter)
  }

}
