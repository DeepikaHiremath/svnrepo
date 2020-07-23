package com.afcdpt.conversion.gxmodel.account.policyConversionBatch

uses gw.processes.BatchProcessBase
uses java.lang.Exception
uses java.util.ArrayList
uses java.sql.Connection
uses java.sql.PreparedStatement
uses com.afcdp.database.AFCConnectionManager
uses com.afcdp.database.AFCPolicyQueryManager
uses java.sql.ResultSet
uses java.util.Date
uses java.util.HashMap
uses gw.transaction.Transaction

/**
 * Created with IntelliJ IDEA.
 * User: AFC7
 * Date: 6/2/20
 * Time: 2:38 PM
 * To change this template use File | Settings | File Templates.
 */
class ConversionPolicyStagingBatch extends BatchProcessBase {
  construct() {
    super(BatchProcessType.TC_POLICYCONTROLSTAGING)
  }

  override function doWork() {
    var legacyPolicyNumbers = findLegacyPoliciesToGeneratePayload()
      OperationsExpected  = legacyPolicyNumbers.Count
    if(legacyPolicyNumbers.Empty){
      print("No Policies to generate payload.")
      return
    }
    legacyPolicyNumbers.each(\legacyPolNum -> {
      try {
        findLegacyDataForPolicyAndCreateAndInsertPayload(legacyPolNum)
      } catch(exception: Exception) {
        exception.printStackTrace()
        incrementOperationsFailed()
        incrementOperationsFailedReasons(exception.Message)
      } finally{
        incrementOperationsCompleted()
      }
    })
  }
  private  function findLegacyPoliciesToGeneratePayload():List<String>{
    var retList = new ArrayList<String>()
    var stagingDBConnection:Connection
    var preparedStatement:PreparedStatement
    try{
      stagingDBConnection = AFCConnectionManager.createStagingDBConnection()
      if(stagingDBConnection == null){
        throw new Exception ("No DB Connection to Staging DB. Cannot query for policies to generate payload")

      }
      preparedStatement = stagingDBConnection.prepareStatement(AFCPolicyQueryManager.querySelectPolNumsToGenPayload)
      var resultSet = preparedStatement.executeQuery()
      while(resultSet.next())  {
        retList.add(resultSet.getString("PolicyNumber"))
      }
    } catch(ex:Exception){
      ex.printStackTrace()
      print("Error in batch" + this.Class.Name + ":" + ex.Message)
    } finally{
      if(preparedStatement !=null) {
        try{
          preparedStatement.close()
        }catch(ex:Exception){
          print("Error in batch"+ this.Class.Name + ":"+ ex.Message)
        }
      }

      if(stagingDBConnection != null){
        try{

          stagingDBConnection.close()
        } catch(ex:Exception){
          print("Error in batch"+ this.Class.Name + ":" + ex.Message)
        }
      }
    }
    return retList
  }

  private  function findLegacyDataForPolicyAndCreateAndInsertPayload(polNum:String):List<String>{
    var returnList = new ArrayList<String>()
    var legacyDBConnection : Connection
    var preparedStatement :PreparedStatement
    try {
      // legacyDBConnection = AFCConnectionManager.createLegacyDBConnection()
      legacyDBConnection = AFCConnectionManager.createLegacyDBConnection()
      if(legacyDBConnection == null){
        throw new Exception ("No DB Connection to Legacy DB. Cannot query for legacy account data for account number:" +polNum)
      }
      preparedStatement = legacyDBConnection.prepareStatement(AFCPolicyQueryManager.querySelectLegacyPolicyData)
      preparedStatement.setObject(1 ,polNum)
      var resultSet = preparedStatement.executeQuery()
      while(resultSet.next()) {
       var payload = createXMLObjFromResultSet(resultSet)

  insertPayloadIntoStagingDB(polNum, payload)


        }

    } catch(ex:Exception) {
      print("Error in batch"+ this.Class.Name + ":"+ ex.Message)
    }finally{
      if(preparedStatement != null){
        try{
          preparedStatement.close()
        } catch(ex:Exception){
          print("Error in batch"+ this.Class.Name + ":"+ ex.Message)
        }
      }
      if(legacyDBConnection !=null){
        try{
          legacyDBConnection.close()
        } catch(ex:Exception){
          print("Error in batch"+ this.Class.Name + ":"+ ex.Message)
        }
      }
    }
    return returnList
  }

   function createXMLObjFromResultSet(resultSet:ResultSet) :String{
     var policyXMLObj = new com.afcdpt.conversion.gxmodel.policyperiod.policyperiodmodel.PolicyPeriod()
     policyXMLObj.AssignedRisk = resultSet.getString("PP_ASGRSK")=="0" ? false : true
     policyXMLObj.BaseState = resultSet.getString("PP_BSST")
     policyXMLObj.PeriodEnd = resultSet.getDate("PP_PERENDT")
     policyXMLObj.PeriodStart = resultSet.getDate("PP_PERSTDT")

     policyXMLObj.Policy = new()
     policyXMLObj.Policy.Account = new()
     policyXMLObj.Policy.Account.AccountNumber = resultSet.getString("PP_ACCNUM")
     policyXMLObj.PolicyLocations = new()
     var polLocEnt =  new com.afcdpt.conversion.gxmodel.policyperiod.policyperiodmodel.anonymous.elements.PolicyPeriod_PolicyLocations_Entry()
     polLocEnt.AccountLocation = new()
     var accLoc = polLocEnt.AccountLocation
     accLoc.AddressLine1 = resultSet.getString("PLAL_AL1")
     accLoc.AddressLine2 = resultSet.getString("PLAL_AL2")
     accLoc.AddressLine3 = resultSet.getString("PLAL_AL3")
     accLoc.City = resultSet.getString("PLAL_CITY")
     accLoc.County = resultSet.getString("PLAL_CNTY")
     accLoc.State = resultSet.getString("PLAL_STATE")
     accLoc.PostalCode = resultSet.getString("PLAL_POSTALCD")
     accLoc.Country = resultSet.getString("PLAL_CNTRY")
     accLoc.Description = resultSet.getString("PLAL_DESC")
     policyXMLObj.PolicyLocations.addChild(polLocEnt)
     policyXMLObj.PolicyNumber = resultSet.getString("PP_POLNUM")
     policyXMLObj.PrimaryNamedInsured = new()
     var pni =  policyXMLObj.PrimaryNamedInsured
     pni.AccountContactRole = new()
     var pniCr = pni.AccountContactRole
     pniCr.AccountContact = new()
     var pniCrAc = pniCr.AccountContact
     pniCrAc.Contact = new()
     var pnCrAcCt =  pniCrAc.Contact
     pnCrAcCt.entity_Person = new()
     pnCrAcCt.entity_Person.FirstName = resultSet.getString("PNI_FNAME")
     pnCrAcCt.entity_Person.LastName = resultSet.getString("PNI_LNAME")
     pnCrAcCt.Name = resultSet.getString("PNI_NAME")
     pnCrAcCt.Subtype = resultSet.getString("PNI_SUBTYP")
     pnCrAcCt.EmailAddress1 = resultSet.getString("PNI_EMAIL1")
     pnCrAcCt.EmailAddress2 = resultSet.getString("PNI_EMAIL2")
     pnCrAcCt.FaxPhone = resultSet.getString("PNI_FAXPH")
     pnCrAcCt.WorkPhone = resultSet.getString("PNI_WORKPH")

     pnCrAcCt.PrimaryAddress = new()
     var primaryAddress = pnCrAcCt.PrimaryAddress
     primaryAddress.AddressLine1 = resultSet.getString("PNIAD_AL1")
     primaryAddress.AddressLine2 = resultSet.getString("PNIAD_AL2")
     primaryAddress.AddressLine3 = resultSet.getString("PNIAD_AL3")
     //primaryAddress.AddressType = resultSet.getString("PNIAD_ADTYPE")
     primaryAddress.City = resultSet.getString("PNIAD_CITY")
     primaryAddress.Country = resultSet.getString("PNIAD_CNTRY")
     primaryAddress.County = resultSet.getString("PNIAD_CNTY")
     primaryAddress.Description = resultSet.getString("PNIAD_DESC")
     primaryAddress.PostalCode = resultSet.getString("PNIAD_POSTAL")
     primaryAddress.State = resultSet.getString("PNIAD_STATE")


     policyXMLObj.ProducerCodeOfRecord = new()
     policyXMLObj.ProducerCodeOfRecord.Code = resultSet.getString("PP_PRODCDID")
     policyXMLObj.TermNumber = resultSet.getString("PP_TMNUM")

     policyXMLObj.UWCompany = new()
     policyXMLObj.UWCompany.Code = resultSet.getString("PP_UWCPCD")

     policyXMLObj.WorkersCompLine = new()

     var wcLine =  policyXMLObj.WorkersCompLine
     wcLine.Jurisdictions = new()

     var jurE = new com.afcdpt.conversion.gxmodel.policyperiod.workerscomplinemodel.anonymous.elements.WorkersCompLine_Jurisdictions_Entry()
     jurE.State = resultSet.getString("WC_JUR")
     wcLine.Jurisdictions.addChild(jurE)

     wcLine.WCCoveredEmployees = new()

     var wcceE =  new com.afcdpt.conversion.gxmodel.policyperiod.workerscomplinemodel.anonymous.elements.WorkersCompLine_WCCoveredEmployees_Entry()
     wcceE.BasisAmount = resultSet.getString("WE_BSAMT")
     wcceE.ClassCode = new()
     wcceE.ClassCode.Code = resultSet.getString("WE_CLSCD")
     wcceE.LocationWM = new()
     var pl = wcceE.LocationWM
     pl.AccountLocation = new()
     var wcceAL =pl.AccountLocation
     wcceAL.AddressLine1 = resultSet.getString("WEAL_AL1")
     wcceAL.AddressLine2 = resultSet.getString("WEAL_AL2")
     wcceAL.AddressLine3 = resultSet.getString("WEAL_AL3")
     wcceAL.City = resultSet.getString("WEAL_CITY")
     wcceAL.County = resultSet.getString("WEAL_CNTY")
     wcceAL.State = resultSet.getString("WEAL_STATE")
     wcceAL.PostalCode = resultSet.getString("WEAL_POSTALCD")
     wcceAL.Country = resultSet.getString("WEAL_CNTRY")
     wcceAL.Description = resultSet.getString("WEAL_DESC")
     wcceE.NumEmployees = resultSet.getString("WE_NUMEMP")
     wcceE.SpecialCov = new()
     wcceE.SpecialCov.Code = resultSet.getString("WE_SPCOV")
     wcLine.WCCoveredEmployees.addChild(wcceE)
     policyXMLObj.WrittenDate = resultSet.getDate("PP_WRITDT")

     return policyXMLObj.asUTFString()
     }

    function  insertPayloadIntoStagingDB(polNum:String,payload:String){

      var stagingDBConnection:Connection
      var preparedStatement:PreparedStatement
      try{
        stagingDBConnection = AFCConnectionManager.createStagingDBConnection()
        if(stagingDBConnection == null){
          throw new Exception ("No DB Connection to Lagacy DB. Cannot query for  Lagacy policy data for policy number:" + polNum)

        }
        preparedStatement = stagingDBConnection.prepareStatement(AFCPolicyQueryManager.queryInsertPolicyPayloadIntoStaging)
        preparedStatement.setObject(1,polNum)
        preparedStatement.setObject(2,payload)
        var insertRows = preparedStatement.executeUpdate()
        if(insertRows == 1){
          updatePolicyPayloadGenerated(polNum)
        }else{
          print("Error could not insert payload in staging table for policy number :"+polNum)
        }
      } catch(ex:Exception){
        ex.printStackTrace()
        print("Error while inserting payload in staging table for policy number :"+polNum)
        print("Error in Batch"+this.Class.Name+":"+ex.Message)

      } finally{
        if(preparedStatement != null){
          try {
            preparedStatement.close()
          }catch(ex:Exception){
            ex.printStackTrace()
            print("Error in Batch"+this.Class.Name+":"+ex.Message)
          }
        }
        if(stagingDBConnection != null){
          try{
            stagingDBConnection.close()
          } catch(ex:Exception){
            ex.printStackTrace()
            print("Error in Batch"+this.Class.Name+":"+ex.Message)
          }
        }
      }
    }


  function updatePolicyPayloadGenerated(polNum:String){
    var stagingDBConnection:Connection
    var preparedStatement:PreparedStatement
    try {
      stagingDBConnection = AFCConnectionManager.createStagingDBConnection()
      if(stagingDBConnection == null){
        throw new Exception("No DB Connection to Legacy DB. Can not update success of creation of policy payload for policy number:" + polNum)
      }
      preparedStatement = stagingDBConnection.prepareStatement(AFCPolicyQueryManager.queryUpdatePolicyPayloadGenerated)
      preparedStatement.setObject(1,Date.Today.toSQLDate())
      preparedStatement.setObject(2,polNum)
      var insertRows = preparedStatement.executeUpdate()
      if(insertRows == 1){

        print(" Update succes of policy payload creation for policy number :"+polNum)
      }
    } catch(ex:Exception){
        ex.printStackTrace()
      print("Error in Batch"+this.Class.Name+":"+ex.Message)

    } finally{
      if(preparedStatement != null){
        try {
          preparedStatement.close()
        }catch(ex:Exception){
          ex.printStackTrace()
          print("Error in Batch"+this.Class.Name+":"+ex.Message)
        }
      }
      if(stagingDBConnection != null){
        try{
          stagingDBConnection.close()
        } catch(ex:Exception){
          ex.printStackTrace()
          print("Error in Batch"+this.Class.Name+":"+ex.Message)
        }
      }
    }
  }


  function updatePolStagingWithErrorReason(polNum : String){
    var stagingDBConnection : Connection
    var preparedStatement : PreparedStatement
    try{
      stagingDBConnection = AFCConnectionManager.createStagingDBConnection()
      if(stagingDBConnection == null){
        throw new Exception("No DB connection to legacy DB. Cannot update success of creation of policy payload for policy number :" + polNum)
      }
      preparedStatement = stagingDBConnection.prepareStatement(AFCPolicyQueryManager.queryUpdatePolIsAlreadyExists)
      preparedStatement.setObject(1,"Policy Already Exists")
      preparedStatement.setObject(2,polNum)
      var insertedRows = preparedStatement.executeUpdate()
      if(insertedRows == 1){
        print("Updated  success of policy Staging table for policy number:"+ polNum)



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
      if(stagingDBConnection != null){
        try{
          stagingDBConnection.close()
        }    catch(ex : Exception){
          print("Error in batch:" + this.Class.Name + ":" + ex.Message)
        }
      }

    }
  }





}