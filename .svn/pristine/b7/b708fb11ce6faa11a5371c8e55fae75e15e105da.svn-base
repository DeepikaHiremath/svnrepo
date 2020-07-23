package com.afcdpt.conversion.gxmodel.policyperiod

uses gw.api.database.Query
uses gw.webservice.pc.pc800.gxmodel.SimpleValuePopulator

/**
 * Created with IntelliJ IDEA.
 * User: AFC7
 * Date: 6/22/20
 * Time: 6:39 PM
 * To change this template use File | Settings | File Templates.
 */
enhancement PolicyPeriodModelEnhancement : com.afcdpt.conversion.gxmodel.policyperiod.policyperiodmodel.types.complex.PolicyPeriod {
  function populatePolicyPeriod(policyPeriod:PolicyPeriod):PolicyPeriod{
    var acNum = this.Policy.Account.AccountNumber
    var account = Query.make(Account).compare(Account#AccountNumber,Equals,acNum).select().first()
    account = policyPeriod.Bundle.add(account)
    SimpleValuePopulator.populate(this,policyPeriod)
    if(!policyPeriod.PolicyNumber.startsWith("L")){
      policyPeriod.PolicyNumber = "L"  + policyPeriod.PolicyNumber
    }
    policyPeriod.UWCompany =Query.make(UWCompany).compare(UWCompany#Code,Equals,this.UWCompany.Code).select().first()
    var accContact = this.PrimaryNamedInsured.AccountContactRole.AccountContact.Contact.$TypeInstance.findMatchingContact(account)
    policyPeriod.changePrimaryNamedInsuredTo(accContact)
    policyPeriod.EditEffectiveDate = policyPeriod.PeriodStart
    this.PolicyLocations?.Entry?.each( \ elt -> elt.$TypeInstance.addPolicyLocation(account,policyPeriod))
    this.WorkersCompLine.$TypeInstance.populateLine(policyPeriod,account)
    return policyPeriod
  }

}
