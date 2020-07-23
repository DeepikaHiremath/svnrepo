package gw.personaldata

uses gw.api.database.IQuery
uses gw.api.database.IQueryBuilder
uses gw.api.personaldata.DataDestructionParameterCheck
uses java.lang.IllegalStateException
uses java.util.Iterator
uses gw.api.database.Query
uses gw.api.database.InOperation
uses gw.lang.reflect.TypeSystem
uses gw.entity.ITypeList

@Export
class PersonalDataDestructionNotifyExternalSystemsWorkQueue extends PersonalDataBulkInsertWorkQueueBase<PersonalDataDestructionRequest> {

  construct() {
    super(BatchProcessType.TC_NOTIFYEXTERNALSYSTEMFORPERSONALDATA, StandardWorkItem, PersonalDataDestructionRequest)
  }

  protected override function findTargets(query : IQueryBuilder) : Iterator {
    DataDestructionParameterCheck.verifyPersonalDataDestructionEnabled();

    /**
     SQL =SELECT
        /* KeyTable:px_pddestructionrequest; */
        qroot.id col0
     FROM   px_pddestructionrequest qRoot
     WHERE  NOT EXISTS
           (
             SELECT groot.pddestructionrequest col0
             FROM   px_contactdestructionreq gRoot
             WHERE  groot.pddestructionrequest = qroot.id
             AND    groot.status NOT IN (?,
                                         ?,
                                         ?)
             AND    groot.pddestructionrequest = qroot.id)
       AND    qroot.requestersnotified = ? [1 (typekey), 4 (typekey), 5 (typekey), false (bit)]
     */
    var typeList = TypeSystem.getByRelativeName("typekey."+ContactDestructionStatus.Type.RelativeName) as ITypeList
    var finishedStatusTypeKeys = typeList.getTypeKeysByCategories(new ContactDestructionStatusCategory[]{ContactDestructionStatusCategory.TC_DESTRUCTIONSTATUSFINISHED})
    var subquery = Query.make(PersonalDataContactDestructionRequest)
        .compare(PersonalDataContactDestructionRequest#PersonalDataDestructionRequest.FeatureInfo.Name, Equals, query.getColumnRef(PersonalDataDestructionRequest#ID.PropertyInfo.Name))
        .compareNotIn(PersonalDataContactDestructionRequest#Status, finishedStatusTypeKeys)
    query.subselect(PersonalDataDestructionRequest#ID, InOperation.CompareNotIn, subquery, PersonalDataContactDestructionRequest#PersonalDataDestructionRequest)
    query.compare(PersonalDataDestructionRequest#RequestersNotified, Equals, false)

    return (query as IQuery).withLogSQL(true).select().iterator() as Iterator<PersonalDataDestructionRequest>
  }

  override function processWorkItem(workItem : StandardWorkItem) {
    DataDestructionParameterCheck.verifyPersonalDataDestructionEnabled();
    var purgeRequest = extractTarget(workItem)

    var successfulNotification = purgeRequest.notifyRequesters()
    if (successfulNotification) {
      purgeRequest.Bundle.commit()
    } else if (not successfulNotification and purgeRequest.RequestersNotified) {
      throw new IllegalStateException("Notification was sent but not marked as notified on PersonalDataDestructionRequest:" + purgeRequest)
    }
  }
}