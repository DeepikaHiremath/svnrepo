package com.afcdpt.conversion.gxmodel.account.policyConversionBatch

uses gw.processes.BatchProcessBase
uses java.lang.Exception
uses java.util.HashMap
uses java.sql.Connection
uses java.sql.PreparedStatement
uses com.afcdp.database.AFCPolicyQueryManager
uses gw.api.database.Query
uses gw.api.productmodel.Product
uses java.util.ArrayList
uses ErrorType
uses com.afcdp.database.AFCConnectionManager
uses java.sql.ResultSet
uses gw.transaction.Transaction


/**
 * Created with IntelliJ IDEA.
 * User: AFC7
 * Date: 6/2/20
 * Time: 3:37 PM
 * To change this template use File | Settings | File Templates.
 */
class ConversionPolicyLoadBatch extends BatchProcessBase {
  construct() {
    super(BatchProcessType.TC_POLICYCONVERSION)
  }

  override function doWork(){
    //var accMissingQuery = "Account Missing"
    //var accSuccessQuery = "SUCCESS"
    var legacyPolMap = queryPolicyPayloads()
    OperationsExpected = legacyPolMap.Count
    if(legacyPolMap.Empty){
      print("No account to convert")
      return
    }
    legacyPolMap.eachKeyAndValue( \ id, payload ->{

      if(TerminateRequested){
        print("Adhoc Termination requested for batch :" + this.Class.Name + ". Discounting execution")
        return
      }
      if(payload?.HasContent){

        try{


          var polXMLObj = com.afcdpt.conversion.gxmodel.policyperiod.policyperiodmodel.PolicyPeriod.parse(payload)
          var newPolNum = polXMLObj.PolicyNumber
          if(!newPolNum.startsWith("V")){
            newPolNum = "V"+ newPolNum
            polXMLObj.PolicyNumber  = newPolNum
          }

          var accNum = polXMLObj.Policy.Account.AccountNumber
          if(!accNum.startsWith("V"))  {
            accNum = "V"+ accNum
            polXMLObj.Policy.Account.AccountNumber = accNum
          }
          var   account = Account.finder.findAccountByAccountNumber(accNum)
          if(account == null) {
            print("Account"+ accNum +"does not exist! can't create policy for policy number"+newPolNum)
            updatePolicyPayloadConvertedError(id)
          }  else {
            print("New Policy Number"+newPolNum)

            var polPeriod = gw.api.database.Query.make(PolicyPeriod).
                compare(PolicyPeriod#PolicyNumber,Equals,newPolNum).select()?.last()
            var existingPolPeriod = polPeriod?.getSlice(polPeriod.EditEffectiveDate)

            // var existingPolPeriod = Policy.finder.findPolicyByPolicyNumber(newPolNum)?.LatestPeriod
            if(existingPolPeriod != null and existingPolPeriod.PeriodDisplayStatus != PolicyPeriodStatus.TC_WITHDRAWN) {
              print("Policy" + existingPolPeriod.PolicyNumber
                  + "already exists with Policy Period in non withdrawn status. Withdrawing Job"+existingPolPeriod.Job.JobNumber)

              Transaction.runWithNewBundle(\ bundle -> {
                existingPolPeriod = bundle.add(existingPolPeriod)
                existingPolPeriod.JobProcess.withdrawJob()
                existingPolPeriod.remove()
                bundle.add(existingPolPeriod.Policy)
                existingPolPeriod.Policy.remove()
              })
              print("Job:"+ existingPolPeriod.Job.JobNumber +" withdran for policy "+existingPolPeriod.PolicyNumber)
            }

            if(existingPolPeriod != null and existingPolPeriod.PeriodDisplayStatus == PolicyPeriodStatus.TC_WITHDRAWN) {

              Transaction.runWithNewBundle(\ bundle -> {
                existingPolPeriod = bundle.add(existingPolPeriod)
                existingPolPeriod.remove()
                bundle.add(existingPolPeriod.Policy)
                existingPolPeriod.Policy.remove()
              })
            }

            Transaction.runWithNewBundle(\ bundle -> {
              account = bundle.add(account)
              var producerCode = gw.api.database.Query.make(ProducerCode).compare(ProducerCode#Code,Equals,polXMLObj.ProducerCodeOfRecord.Code).select().first()
              var product = gw.api.productmodel.ProductLookup.getByPublicID("WorkersComp")
              var renewal =  account.createConversionRenewalWithBasedOn(polXMLObj.PeriodStart,polXMLObj.PeriodEnd,product,producerCode,polXMLObj.PolicyNumber,\period ->{
                //polXMLObj.$TypeInstance.populatePolicyPeriod(period)
                polXMLObj.$TypeInstance.populatePolicyPeriod(period)
                var covs  = period.WorkersCompLine.Pattern.getCoverageCategory("WorkersCompGrp").coveragePatternsForEntity(WorkersCompLine)
                    .whereSelectedOrAvailable(period.WorkersCompLine,true).where( \ c ->c.DisplayName != "Worker' Comp" )
                covs.each( \ elt -> period.WorkersCompLine.getOrCreateCoverage(elt) )

              })
              print("Conversion renewal created :" + renewal.JobNumber)
              print(renewal.JobNumber)

            },"su")
            updatePolicyPayloadConvertedStatus(id)
          }



        } catch(ex: Exception){
          ex.printStackTrace()
          incrementOperationsFailed()
          incrementOperationsFailedReasons(ex.Message)
        }   finally{
          incrementOperationsCompleted()
        }
      }
    } )

  }


  // Function to query payload from conversionControltable
 private  function queryPolicyPayloads():HashMap<String,String>{
    var returnMap = new HashMap<String,String>()
    var stagingDBConnection:Connection
    var preparedStatement:PreparedStatement
    try {
    stagingDBConnection = AFCConnectionManager.createAccConversionDBConnection()
    if(stagingDBConnection == null){
    throw new Exception("No DB Connection to staging DB. Can not query  for policies  to convert payload")
    }
    preparedStatement = stagingDBConnection.prepareStatement(AFCPolicyQueryManager.querySelectDmWcPayloadToConvert )

    var resultSet = preparedStatement.executeQuery()
    while(resultSet.next()){
    returnMap.put(resultSet.getString("id"),resultSet.getString("payload"))

    }
    }catch(ex:Exception){
    ex.printStackTrace()
    print("Error in batch" + this.Class.Name + ":" + ex.Message)
    }finally{
    if(preparedStatement!= null){
    try{
    preparedStatement.close()
    } catch(ex:Exception) {
    ex.printStackTrace()

    print("Error in batch" + this.Class.Name + ":" + ex.Message)
    }
    }
    if(stagingDBConnection != null){
    try {
    stagingDBConnection.close()
    }catch(ex:Exception){
    ex.printStackTrace()

    print("Error in batch" + this.Class.Name + ":" + ex.Message)
    }
    }
    }
    return returnMap
    }



 // function update conversoncontroltable where status is null
function updatePolicyPayloadConvertedStatus(id : String){

  var conversionDBConnection : Connection
  var preparedStatement : PreparedStatement
  try{
    conversionDBConnection = AFCConnectionManager.createAccConversionDBConnection()
    if(conversionDBConnection == null){
      throw new Exception("No DB connection to legacy DB. Cannot update success of creation of policy payload for account number :" + id)
    }
    preparedStatement  = conversionDBConnection.prepareStatement(AFCPolicyQueryManager.queryUpdateDmWcPayloadConverted)
    preparedStatement.setObject(1,id)
    var insertedRows = preparedStatement.executeUpdate()
    if(insertedRows == 1){
      print("Updated success of Policy payload creation for account number :" +id)
    }
  }catch(ex : Exception){
    print("Error in batch:" +  this.Class.Name + ":" +  ex.Message)
  } finally {
    if(preparedStatement != null){
      try{
        preparedStatement.close()

      }  catch( ex : Exception){
        print("Error in Batch:" + this.Class.Name +  ":" + ex.Message)

      }

    }
    if(conversionDBConnection != null){
      try{
        conversionDBConnection.close()
      }    catch(ex : Exception){
        print("Error in batch:" + this.Class.Name + ":" + ex.Message)
      }
    }

  }

}
  // function update conversioncontroltable set error
  function updatePolicyPayloadConvertedError(id : String){
    var conversionDBConnection : Connection
    var preparedStatement : PreparedStatement
    try{
      conversionDBConnection = AFCConnectionManager.createAccConversionDBConnection()
      if(conversionDBConnection == null){
        throw new Exception("No DB connection to legacy DB. Cannot update success of creation of policy payload for account number :" + id)
      }
      preparedStatement  = conversionDBConnection.prepareStatement(AFCPolicyQueryManager.queryUpdateDmWcPayloadExists)
      preparedStatement.setObject(1,id)
      var insertedRows = preparedStatement.executeUpdate()
      if(insertedRows == 1){
        print("Updated success of Policy payload creation for account number :" +id)
      }
    }catch(ex : Exception){
      print("Error in batch:" +  this.Class.Name + ":" +  ex.Message)
    } finally {
      if(preparedStatement != null){
        try{
          preparedStatement.close()

        }  catch( ex : Exception){
          print("Error in Batch:" + this.Class.Name +  ":" + ex.Message)

        }

      }
      if(conversionDBConnection != null){
        try{
          conversionDBConnection.close()
        }    catch(ex : Exception){
          print("Error in batch:" + this.Class.Name + ":" + ex.Message)
        }
      }

    }
}



}






