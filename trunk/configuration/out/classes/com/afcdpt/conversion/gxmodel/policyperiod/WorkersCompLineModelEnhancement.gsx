package com.afcdpt.conversion.gxmodel.policyperiod
/**
 * Created with IntelliJ IDEA.
 * User: AFC7
 * Date: 6/22/20
 * Time: 6:36 PM
 * To change this template use File | Settings | File Templates.
 */
enhancement WorkersCompLineModelEnhancement : com.afcdpt.conversion.gxmodel.policyperiod.workerscomplinemodel.types.complex.WorkersCompLine {
  function populateLine(policyPeriod:PolicyPeriod,account:Account) {
    this.WCCoveredEmployees?.Entry.each( \ elt -> elt.$TypeInstance.createWCCoveredEmployee(policyPeriod,account))
    this.Jurisdictions?.Entry.each( \ elt -> elt.$TypeInstance.addJurisdiction(policyPeriod))
  }


}
