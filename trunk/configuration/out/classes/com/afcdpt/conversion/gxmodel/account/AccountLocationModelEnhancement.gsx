package com.afcdpt.conversion.gxmodel.account

uses gw.pl.persistence.core.Bundle
/**
 * Created with IntelliJ IDEA.
 * User: AFC7
 * Date: 5/21/20
 * Time: 9:01 AM
 * To change this template use File | Settings | File Templates.
 */
enhancement AccountLocationModelEnhancement : com.afcdpt.conversion.gxmodel.account.accountlocationmodel.types.complex.AccountLocation {
     function findOrCreateAccountLocation(bundle:Bundle, account:Account):AccountLocation{
       var returnLocation = account.AccountLocations.firstWhere( \ elt ->
       elt.AddressLine1 == this.AddressLine1 and
       elt.AddressLine2 == this.AddressLine2 and
       elt.AddressLine3 == this.AddressLine3 and
      // elt.AddressType == this.AddressType and
       elt.City == this.City and
       elt.County == this.County and
       elt.Country == this.Country and
       elt.Description == this.Description and
       elt.NonSpecific == this.NonSpecific and
       elt.PostalCode == this.PostalCode and
       elt.State == this.State
       )
       if(returnLocation == null){
         returnLocation = account.newLocation()
         returnLocation.AddressLine1 = this.AddressLine1
         returnLocation.AddressLine2 = this.AddressLine2
         returnLocation.AddressLine3 = this.AddressLine3
         returnLocation.City = this.City
         returnLocation.Country = this.Country
         returnLocation.County = this.County
         returnLocation.Description = this.Description
         returnLocation.NonSpecific = this.NonSpecific
         returnLocation.PostalCode = this.PostalCode
         returnLocation.State = this.State
       }
       return returnLocation
     }
}
