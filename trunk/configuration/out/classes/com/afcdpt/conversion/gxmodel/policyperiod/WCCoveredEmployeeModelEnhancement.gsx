package com.afcdpt.conversion.gxmodel.policyperiod

uses gw.api.util.CoreFilters.Equals
uses gw.api.database.Query

/**
 * Created with IntelliJ IDEA.
 * User: AFC7
 * Date: 6/22/20
 * Time: 6:30 PM
 * To change this template use File | Settings | File Templates.
 */
enhancement WCCoveredEmployeeModelEnhancement : com.afcdpt.conversion.gxmodel.policyperiod.wccoveredemployeemodel.types.complex.WCCoveredEmployee {
  function createWCCoveredEmployee (policyPeriod:PolicyPeriod, account:Account) {
    // var wcE = policyperiod.WorkersCompLine.createAnaAddWCCoveredEmployee()
    var wcE = new WCCoveredEmployee(policyPeriod)
    wcE.WorkersCompLine = policyPeriod.WorkersCompLine
    wcE.BasisAmount = this.BasisAmount
    wcE.ClassCode = Query.make(WCClassCode).compare(WCClassCode#Code,Equals, this.ClassCode.Code).select().first()
    wcE.Location = policyPeriod.getPolicyLocation(this.LocationWM.AccountLocation.$TypeInstance.findOrCreateAccountLocation(policyPeriod.Bundle,account))
    wcE.NumEmployees = this.NumEmployees
    wcE.SpecialCov = this.SpecialCov.Code
  }

}
