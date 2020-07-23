package gw.rating.rtm.excel

uses java.lang.Integer

//mimics RateRoutineDetailsScreen.pcf
enhancement CalcStepDefinitionExportEnhancement : entity.CalcStepDefinition {

  property get Column_StepNumber() : Integer {
    return this.SortOrder
  }

  property get Column_Instruction() : String {
    if (this.IsSectionCommentStep) {
      return displaykey.Web.Rating.Flow.CalcRoutine.SectionComment
    } else {
      var stepCategory = this.StepType.Categories.whereTypeIs(CalcStepCategory).first()
      switch (stepCategory) {
        case typekey.CalcStepCategory.TC_ASSIGNMENT:
          return this.StoreLocationForDisplay
        case typekey.CalcStepCategory.TC_FLOWCONTROL:
          return this.StepType.DisplayName
        case typekey.CalcStepCategory.TC_VOIDFUNCTION:
          return this.PrimaryOperand.OperandName
        default:
          return " "
      }
    }
  }

  property get Column_Op() : String {
    if (this.IsSectionCommentStep) {
      return this.SectionComment
    } else if (this.IsVoidFunctionStep) {
      return this.Notes
    } else {
      return this.PrimaryOperand.OperatorType.DisplayName
    }
  }

  property get Column_LeftParenthesis() : String {
    if (this.IsSectionCommentStep or this.IsVoidFunctionStep) {
      return null
    }
    return this.PrimaryOperand.LeftParenthesisGroup
  }

  property get Column_Operand() : String {
    if (this.IsSectionCommentStep or this.IsVoidFunctionStep) {
      return null
    }
    return this.PrimaryOperand.OperandName
  }

  property get Column_RightParenthesis() : String {
    if (this.IsSectionCommentStep or this.IsVoidFunctionStep) {
      return null
    }
    return this.PrimaryOperand.RightParenthesisGroup
  }

  property get Column_Comments() : String {
    if (this.IsSectionCommentStep or this.IsVoidFunctionStep) {
      return null
    }
    return this.Notes
  }

}
