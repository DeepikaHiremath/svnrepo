package com.afcdpt.conversion.gxmodel.policyperiod
/**
 * Created with IntelliJ IDEA.
 * User: AFC7
 * Date: 6/22/20
 * Time: 6:27 PM
 * To change this template use File | Settings | File Templates.
 */
enhancement PolicyLocationModelEnhancement : com.afcdpt.conversion.gxmodel.policyperiod.policylocationmodel.types.complex.PolicyLocation {
  function addPolicyLocation(account:Account,policyPeriod:PolicyPeriod ) {
    var accLoc = this.AccountLocation.$TypeInstance.findOrCreateAccountLocation(policyPeriod.Bundle,account )
    if(policyPeriod.getPolicyLocation(accLoc) == null){
      policyPeriod.newLocation(accLoc)
    }
  }


}
