package com.afcdpt.conversion.gxmodel.account

uses gw.pl.persistence.core.Bundle
uses gw.api.database.Query
uses gw.api.database.Relop

/**
 * Created with IntelliJ IDEA.
 * User: AFC7
 * Date: 5/21/20
 * Time: 9:42 AM
 * To change this template use File | Settings | File Templates.
 */
enhancement AccountModelEnhancement : com.afcdpt.conversion.gxmodel.account.accountmodel.types.complex.Account {
           function createAccount(bundle:Bundle):Account{
              var contact = this.AccountHolderContact.$TypeInstance.createContact(bundle)
             var account = Account.createAccountForContact(contact)
             account.AccountNumber = this.AccountNumber
             this.AccountLocations?.Entry?.each( \ elt -> {
               elt.$TypeInstance.findOrCreateAccountLocation(bundle,account)
             })
             account.AccountOrgType = this.AccountOrgType
             if(this.IndustryCode != null and this.IndustryCode.Code != null){
               var inCodeQuery = Query.make(IndustryCode) .compare(IndustryCode#Code, Equals ,this.IndustryCode.Code).select().AtMostOneRow
               account.IndustryCode = inCodeQuery
             }
             account.PrimaryLocation = this.PrimaryLocation.$TypeInstance.findOrCreateAccountLocation(bundle,account)
             this.ProducerCodes?.Entry?.each( \ elt -> {
               var pcQuery = Query.make(ProducerCode).compare(ProducerCode#Code, Relop.Equals,elt.ProducerCode.Code).select().AtMostOneRow
               account.addProducerCode(pcQuery)
             })
             account.ServiceTier = this.ServiceTier
             return account
           }
}

