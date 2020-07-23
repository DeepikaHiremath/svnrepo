package gw.command.jobs

uses com.guidewire.pl.quickjump.Argument
uses com.guidewire.pl.quickjump.Arguments
uses com.guidewire.pl.quickjump.DefaultMethod
uses com.guidewire.pl.quickjump.BaseCommand
uses gw.api.builder.PolicyChangeBuilder
uses gw.api.builder.SubmissionBuilder
uses gw.api.databuilder.UniqueKeyGenerator
uses gw.api.databuilder.pa.PASubmissionBuilder
uses gw.api.util.Range
uses gw.command.critical.Constants

uses java.lang.Integer

/**
* This command is supported by DEV and is required to work. Any change to this Test must pass
* PolicyCommandTest
*/
@Export
@DefaultMethod("wFutureVehicle")
class MultiSliceJob extends BaseCommand {

  @Argument("JobType", Constants.JOB_TYPES)
  function wFutureVehicle() : PolicyPeriod {
    var jobType = getArgumentAsString("JobType")
    var period = makePeriod(jobType, {Range.from(2 * 30)})
    pcf.JobForward.go(period.Job, period)
    return period
  }

  @Arguments("wFutureVehicle")
  function wTempVehicle() : PolicyPeriod {
    var jobType = getArgumentAsString("JobType")
    var period = makePeriod(jobType, {Range.closedOpen(2 * 30, 3 * 30)})
    pcf.JobForward.go(period.Job, period)
    return period
  }

  @Arguments("wFutureVehicle")
  function wTwoVehicles() : PolicyPeriod {
    var jobType = getArgumentAsString("JobType")
    var period = makePeriod(jobType, {Range.closedOpen(2 * 30, 3 * 30), Range.from(2 * 30 + 10)})
    pcf.JobForward.go(period.Job, period)
    return period
  }

  function makePeriod(jobType : String, ranges : List<Range<Integer>>) : PolicyPeriod {
    jobType = jobType ?: "submission"
    var period : PolicyPeriod
    gw.transaction.Transaction.runWithNewBundle(\ bundle -> {
      var builder = new PASubmissionBuilder()
      if (jobType == "submission") {
        period = builder.isDraft().create(bundle)
        for (range in ranges) {
          period = period.getSlice(period.PeriodStart.addDays(range.Start))
          createVehicleSliceInRange(period, range)
        }
      } else {
        period = builder.isBound().create(bundle)
        period = new PolicyChangeBuilder(period).isDraft().create(bundle)
        for (range in ranges) {
          period = period.getSlice(period.PeriodStart.addDays(range.Start))
          createVehicleSliceInRange(period, range)
        }
      }
    })
    return period
  }

  private function createVehicleSliceInRange(period : PolicyPeriod, range : Range<Integer>) {
    var vin = "ABC" + UniqueKeyGenerator.get().nextKey()
    var start = range.Start
    var end = range.End
    var location = period.PolicyLocations[0]
    period = period.getSlice(period.PeriodStart.addDays(start))
    var vehicle = period.PersonalAutoLine.createAndAddVehicle()
    vehicle.Vin = vin
    vehicle.LicenseState = location.State
    vehicle.GarageLocation = location
    vehicle.CostNew = null
    var vehicleDriver = vehicle.addPolicyDriver(period.PersonalAutoLine.PolicyDrivers[0])
    vehicleDriver.PercentageDriven = 100
    vehicle.createCoverages()
    if (end != null and end != start) {
      vehicle = vehicle.getSlice(period.PeriodStart.addDays(end))
      vehicle.remove()
    }
    period.Bundle.commit()
  }

}
