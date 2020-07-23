package gw.rating

uses gw.api.productmodel.PolicyLinePatternLookup
uses gw.rating.rtm.util.ProductModelUtils

enhancement GenericRateBookFieldEnhancement: gw.rating.GenericRateBookFieldSearch {

  function policyLineCodeToDescription(code : String) : String {
    return code == GenericRateBookFieldSearch.GENERIC_POLICY_LINE_CODE
        ? displaykey.Web.Rating.Filter.Generic
        : PolicyLinePatternLookup.getByCode(code).DisplayName
  }

  function offeringCodeToDescription(code : String) : String {
    return code == GenericRateBookFieldSearch.GENERIC_OFFERING_CODE
        ? displaykey.Web.Rating.Filter.Generic
        : ProductModelUtils.getOfferingDisplayName(code)
  }

}
