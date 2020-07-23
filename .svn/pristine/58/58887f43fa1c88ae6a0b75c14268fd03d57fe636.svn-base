package gw.account

uses gw.api.database.BooleanExpression
uses gw.api.database.InOperation
uses gw.api.database.Queries;
uses gw.api.database.Relop
uses gw.api.database.Restriction
uses gw.api.system.PCConfigParameters;
uses gw.processes.WorkQueueBase
uses typekey.AccountStatus;
uses typekey.BatchProcessType;
uses java.util.Iterator;
uses java.lang.SuppressWarnings
uses java.util.Date
uses gw.api.database.Query

/**
 * Evaluates accounts and closes them.
 */
@Export
class AccountWithdrawWorkQueue extends WorkQueueBase<Account, StandardWorkItem> {

  construct() {
    super(BatchProcessType.TC_ACCOUNTWITHDRAW, StandardWorkItem, Account)
  }

  override function processWorkItem(standardWorkItem : StandardWorkItem) {
    var account = extractTarget(standardWorkItem)
    account.AccountStatus = AccountStatus.TC_WITHDRAWN
    account.Bundle.commit()
  }

  @SuppressWarnings("unchecked")
  override function findTargets() : Iterator<Account> {
    var query = Queries.createQuery(getTargetType())
    /**
     * Closes them (status ==> Withdrawn) if
     * There are no policies associated with the account
     * The Account.CreateTime or Account.OriginationDate is older than a configurable number of months in the past (config.xml, set to 37 months)
     * There are no open Activities associated with the Account
     */
    // Find accounts that don't have any associated policies
    var queryPolicy = Query.make(Policy)
    query.subselect(Account#ID, InOperation.CompareNotIn, queryPolicy, Policy#Account)

    // Find accounts without open activities
    var queryActivity = Query.make(Activity);
    queryActivity.compareIn(Activity#Status, ActivityStatus.TF_RETAINACCOUNT.TypeKeys.toTypedArray());
    query.subselect(Account#ID, InOperation.CompareNotIn, queryActivity, Activity#Account)

    // Check the dates
    var allowableDate = Date.Today.addMonths(-PCConfigParameters.AccountsWithdrawnAfterMonths.getValue())
    query.or(\ restrictionOr : Restriction -> {
            // If the origination date is non-null, use it for date comparison
            restrictionOr.and(\ restrictionAnd : Restriction -> {
                            restrictionAnd.compare(Account#OriginationDate, Relop.NotEquals, null)
                            restrictionAnd.compare(Account#OriginationDate, Relop.LessThan, allowableDate)
                          })
            // Otherwise, if the origination date is null, use the create time
            restrictionOr.and(\ restrictionAnd2 : Restriction -> {
                            restrictionAnd2.compare(Account#OriginationDate, Relop.Equals, null)
                            restrictionAnd2.compare(Account#CreateTime, Relop.LessThan, allowableDate)
                          })
          })

    /* The entire sql query is as follows:
    SELECT FROM pc_account qRoot WHERE NOT EXISTS (SELECT qRoot0.AccountID col0
    FROM pc_policy qRoot0 WHERE qRoot0.AccountID = qRoot.ID AND qRoot0.Retired = 0)
    AND NOT EXISTS (SELECT qRoot1.AccountID col0 FROM pc_activity qRoot1 WHERE qRoot1.Status = ? AND qRoot1.AccountID = qRoot.ID AND qRoot1.Retired = 0) AND
    qRoot.Retired = 0 AND ((((((((qRoot.OriginationDate IS NOT NULL) AND (qRoot.OriginationDate < ?))))) OR
    (((((qRoot.OriginationDate IS NULL) AND (qRoot.CreateTime < ?))))))))*/
    return query.withLogSQL(true).select().iterator() as Iterator<Account>
  }
}
