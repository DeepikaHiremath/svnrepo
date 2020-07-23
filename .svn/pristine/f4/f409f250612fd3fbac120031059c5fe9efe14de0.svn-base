package gw.rating.flow

uses java.lang.Integer
uses java.util.Map
uses java.util.HashMap
uses java.lang.IllegalStateException

enhancement CalcRoutineDefinitionUIEnhancement : entity.CalcRoutineDefinition {

  property get StepIndentLevels() : Map<CalcStepDefinition, Integer> {
    var orderedSteps = this.OrderedSteps
    var indentation = 0
    var indentMap = new HashMap<CalcStepDefinition, Integer> ()
    for (step in orderedSteps) {
      if (step.StepType.hasCategory(CalcStepCategory.TC_FLOWCONTROL) and step.StepType <> TC_IF) {
        if (indentation > 0) {
          // in case the rate routine starts with something funny like an else, don't go negative.
          indentation--
        }
      }
      indentMap.put(step, indentation)
      if (step.StepType.hasCategory(CalcStepCategory.TC_FLOWCONTROL) and step.StepType <> TC_ENDIF) {
        indentation++
      }
    }
    return indentMap
  }

  function indentValue(step: CalcStepDefinition, value: String, indentLevelMap: Map<CalcStepDefinition, Integer>) : String {
    if (value == null) return ""
    var indent = indentLevelMap.get(step)
    if (indent == null) {
      throw new IllegalStateException("row was not in rateRoutine's list of steps!")
    }
    return indent > 4 ? displaykey.Web.Rating.Flow.CalcRoutine.IndentationLevelFive(value)
        : (indent > 3) ? displaykey.Web.Rating.Flow.CalcRoutine.IndentationLevelFour(value)
            : (indent > 2) ? displaykey.Web.Rating.Flow.CalcRoutine.IndentationLevelThree(value)
                : (indent > 1) ? displaykey.Web.Rating.Flow.CalcRoutine.IndentationLevelTwo(value)
                    : (indent > 0) ? displaykey.Web.Rating.Flow.CalcRoutine.IndentationLevelOne(value) : value
  }

}
