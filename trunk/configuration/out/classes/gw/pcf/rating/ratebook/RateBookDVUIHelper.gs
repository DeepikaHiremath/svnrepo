package gw.pcf.rating.ratebook

uses java.util.Date

@Export
class RateBookDVUIHelper {
  var _rateBook: RateBook as RateBook

  construct(rateBook : RateBook) {
    _rateBook = rateBook
  }

  property get StatusChangeDateLabel() : String {
    return RateBook.isActive()
        ? displaykey.Web.Rating.RateBooks.ActivationDate
        : displaykey.Web.Rating.RateBooks.LastStatusChangeDate
  }

  function possiblyAutoPopulateRenewalEffectiveDate() {
    if (RateBook.RenewalEffectiveDate == null)
      RateBook.RenewalEffectiveDate = RateBook.EffectiveDate
  }

  function checkDateIsEarlierThanBefore(targetDate : Date) : String {
    if (RateBook.ExpirationDate == null) {return null}
    if (targetDate != null and RateBook.ExpirationDate <= targetDate) {
      return displaykey.Web.Rating.RateBooks.DateIsNotEarlierThanBefore(displaykey.Web.Rating.RateBooks.RenewalEffectiveDate.Before)
    }
    return null
  }

  function checkBeforeOccursLaterThanPolicyEffectiveDateOrRenewalEffectiveDate() : String {
    if (RateBook.ExpirationDate == null) {
      return null
    }
    if ((RateBook.EffectiveDate != null and RateBook.ExpirationDate <= RateBook.EffectiveDate) or
        (RateBook.RenewalEffectiveDate != null and RateBook.ExpirationDate <= RateBook.RenewalEffectiveDate)) {
      return displaykey.Web.Rating.RateBooks.BeforeMustBeLaterThanOnOrAfter(displaykey.Web.Rating.RateBooks.EffectiveDate.After)
    }
    return null
  }

  property get AreRateTablesReferenced() : Boolean {
    var rateTables = _rateBook.RateTables.where( \ elt -> not elt.Owned)
    return rateTables.IsEmpty?false:true
  }

  function makeRateTablesOwned() {
    var rtFromBundle: RateTable
    gw.transaction.Transaction.runWithNewBundle(\ bundle -> {
      _rateBook.RateTables.each( \ rt -> {
        if(not rt.Owned){
          rtFromBundle = bundle.add(rt)
          rtFromBundle.makeOwned()
        }
      })
    })
  }

  function displayMakeOwnedIcon() : boolean {
    return _rateBook.isStage() and AreRateTablesReferenced
  }

}