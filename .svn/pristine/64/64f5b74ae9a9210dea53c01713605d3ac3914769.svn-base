package com.afcdpt.conversion.gxmodel.account

uses gw.pl.persistence.core.Bundle
/**
 * Created with IntelliJ IDEA.
 * User: AFC7
 * Date: 5/20/20
 * Time: 2:53 PM
 * To change this template use File | Settings | File Templates.
 */
enhancement ContactModelEnhancement : com.afcdpt.conversion.gxmodel.account.contactmodel.types.complex.Contact {
      function createContact(bundle:Bundle):Contact{
        var contact = this.Subtype == typekey.Contact.TC_PERSON? new person(bundle):new Company(bundle)
        contact.EmailAddress1 = this.EmailAddress1
        contact.EmailAddress2 = this.EmailAddress2
        if(contact typeis person){
          contact.FirstName = this.entity_Person.FirstName
          contact.LastName = this.entity_Person.LastName

        }
        contact.Name = this.Name
        contact.PrimaryAddress = this.PrimaryAddress.$TypeInstance.createAddress(bundle)
        contact.FaxPhone = this.FaxPhone
        contact.WorkPhone = this.WorkPhone
        return contact
      }

  function findMatchingContact(account:Account): Contact {
    var con = account.AccountContacts.Contact.firstWhere( \ elt ->
        elt.Subtype == this.Subtype and
            elt.EmailAddress1 == this.EmailAddress1 and
            elt.EmailAddress2 == this.EmailAddress2 and
            elt.Name == this.Name
    )
    return con
  }

}
