package com.afcdpt.conversion.gxmodel.policyperiod
/**
 * Created with IntelliJ IDEA.
 * User: AFC7
 * Date: 6/22/20
 * Time: 6:33 PM
 * To change this template use File | Settings | File Templates.
 */
enhancement WCJurisdictionModelEnhancement : com.afcdpt.conversion.gxmodel.policyperiod.wcjurisdictionmodel.types.complex.WCJurisdiction {
  function addJurisdiction(policyPeriod:PolicyPeriod){
    policyPeriod.WorkersCompLine.addJurisdiction(this.State)
  }

}
