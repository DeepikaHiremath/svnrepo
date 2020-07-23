package com.afcdpt.conversion.gxmodel.account

uses gw.pl.persistence.core.Bundle
/**
 * Created with IntelliJ IDEA.
 * User: AFC7
 * Date: 5/20/20
 * Time: 2:41 PM
 * To change this template use File | Settings | File Templates.
 */
enhancement AddressModelEnhancement : com.afcdpt.conversion.gxmodel.account.addressmodel.types.complex.Address {
  function createAddress(bundle:Bundle):Address{
      var address = new Address(bundle)
    address.AddressLine1 = this.AddressLine1
    address.AddressLine2 = this.AddressLine2
    address.AddressLine3 = this.AddressLine3
    address.City = this.City
    address.Country = this.Country
    address.County = this.County
    address.Description = this.Description
    address.PostalCode = this.PostalCode
    address.State = this.State
    return address

  }

}
