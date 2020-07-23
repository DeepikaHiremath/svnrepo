package com.afcdpt.conversion.gxmodel.account.account
uses gw.processes.BatchProcessBase
uses gw.api.database.Query
uses gw.api.database.Relop
uses gw.transaction.Transaction
uses gw.webservice.pc.pc800.account.AccountAPI
uses java.lang.Exception
uses java.util.HashMap
uses com.afcdp.database.AFCConnectionManager
uses java.sql.PreparedStatement
uses java.sql.Connection
uses com.afcdp.database.AFCQueryManager

/**
 * Created with IntelliJ IDEA.
 * User: AFC7
 * Date: 5/21/20
 * Time: 6:15 PM
 * To change this template use File | Settings | File Templates.
 */
class ConversionAccountBatch extends BatchProcessBase {
  construct() {
    super(BatchProcessType.TC_ACCOUNTCONVERSION)
  }

  override function doWork() {
    // connect to lagacy DB
    // var accExistQuery = "ERROR"
    // var accSuccessQuery = "SUCCESS"
    var legacyAccMap = queryAccountPayloads()
    OperationsExpected = legacyAccMap.Count
    if(legacyAccMap.Empty){
      print("No account is convert")
      return
    }

    legacyAccMap.eachKeyAndValue( \ id, payload ->{
      if(TerminateRequested){
        print("Adhoc termination requested for batch:"+ this.Class.Name + ". Discontinuing execution")
        return
        }
      if(payload?.HasContent){

        try{

          var accountXML =  com.afcdpt.conversion.gxmodel.account.accountmodel.Account.parse(payload)
          var newAccNum = accountXML.AccountNumber
          if(!newAccNum.startsWith("L")){
             newAccNum = "L"+ newAccNum
              accountXML.AccountNumber = newAccNum
          }
          if(Account.finder.findAccountByAccountNumber(newAccNum) != null){
            print("Account" + newAccNum + "is already exist! can't create Account again")
           updateAccountPayloadConvertedError(id)
        } else  {
          Transaction.runWithNewBundle(\ bundle -> {
            var account = accountXML.$TypeInstance.createAccount(bundle)
            },"su")
           // updateAccountPayloadConverted(accNum)
            updateAccountPayloadConvertedStatus(id)
           }
          } catch(ex:Exception){
          incrementOperationsFailed()
          incrementOperationsFailedReasons(ex.Message)
            }finally {
          incrementOperationsCompleted()
           }
        }
     })

    }

  function updateAccountPayloadConvertedError(id:String){
  var stagingDBConnection:Connection
  var preparedStatement:PreparedStatement
  try {
  stagingDBConnection = AFCConnectionManager.createAccConversionDBConnection()
  if(stagingDBConnection == null){
  throw new Exception("No DB Connection to Legacy DB. Can not update success of conversion of account payload for account number:")
  }
  preparedStatement = stagingDBConnection.prepareStatement(AFCQueryManager.queryUpdateDMAccountExists)
  preparedStatement.setObject(1,id)

  var  insertedRows = preparedStatement.executeUpdate()
  if(insertedRows == 1){
  print("Updated  error for id which is Already exists:"+ id)
  }

  } catch(ex : Exception){

  print("Error in batch :"+ this.Class.Name + ":" + ex.Message)

  } finally{
  if(preparedStatement != null){
  try{
  preparedStatement.close()
  } catch(ex : Exception){
  print("Error in batch:" + this.Class.Name + ":" + ex.Message)
  }
  }
 }

}


  function queryAccountPayloads():HashMap<String,String> {
  var returnMap = new HashMap<String,String>()
  var stagingDBConnection:Connection
  var preparedStatement:PreparedStatement
  try {
  stagingDBConnection = AFCConnectionManager.createAccConversionDBConnection()
  if(stagingDBConnection == null){
  throw new Exception("No DB Connection to staging DB. Can not query  for accounts to convert payload")
  }
  preparedStatement = stagingDBConnection.prepareStatement(AFCQueryManager.querySelectDmAcctPayloadToConvert)
  var resultSet = preparedStatement.executeQuery()
  while(resultSet.next()){
  returnMap.put(resultSet.getInt("id"),resultSet.getString("payload"))
  }
  }catch(ex:Exception){
  print("Error in batch" + this.Class.Name + ":" + ex.Message)
  }finally{
  if(preparedStatement!= null){
  try{
  preparedStatement.close()
  } catch(ex:Exception) {
  print("Error in batch" + this.Class.Name + ":" + ex.Message)
  }
  }
  if(stagingDBConnection != null){
  try {
  stagingDBConnection.close()
  }catch(ex:Exception){
  print("Error in batch" + this.Class.Name + ":" + ex.Message)
  }
  }
  }
  return returnMap
  }

   function updateAccountPayloadConvertedStatus(id : String){
     var stagingDBConnection : Connection
     var preparedStatement : PreparedStatement
     try{
       stagingDBConnection = AFCConnectionManager.createAccConversionDBConnection()
       if(stagingDBConnection == null){
         throw new Exception("No DB Connectionto legacy DB. Cannot update success of conversion of account payload of account number:")
       }
       preparedStatement =stagingDBConnection.prepareStatement(AFCQueryManager.queryUpdateDMAccPayloadConverted)
       preparedStatement.setObject(1,id)
       var insertedRows = preparedStatement.executeUpdate()
       if(insertedRows == 1){
         print("Updated  success of Account Payload conversion for account number:"+ id)

       }
     }catch(ex : Exception){

       print("Error in batch :"+ this.Class.Name + ":" + ex.Message)

     }   finally{
       if(preparedStatement != null){
         try{
           preparedStatement.close()
         } catch(ex : Exception){
           print("Error in batch:" + this.Class.Name + ":" + ex.Message)
         }
       }
     }
  }

}













