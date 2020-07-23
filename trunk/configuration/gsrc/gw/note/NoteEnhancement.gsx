package gw.note

uses com.guidewire.commons.metadata.MetadataDependencies
uses com.guidewire.commons.metadata.i18n.config.GWLocale
uses gw.i18n.ILocale
uses gw.transaction.Transaction
uses org.apache.commons.lang.StringUtils
uses java.util.Map
uses gw.api.util.DisplayableException
uses gw.api.util.LocaleUtil
uses java.io.StringReader
uses gw.document.TemplatePluginUtils
uses java.util.Date

enhancement NoteEnhancement : Note {
  static function getLevelDisplayString(value : Object) : String {
    if(value typeis Account) {
      return displaykey.Java.Note.AccountLevelNote(value)
    } else if (value typeis Policy) {
      var period = entity.Policy.finder.findPolicyPeriodByPolicyAndAsOfDate(value, DateTime.Today)
      if (period == null) {
        period = value.Periods.last()
      }
      return displaykey.Java.Note.PolicyLevelNote(period.PolicyNumberDisplayString)
    } else if (value typeis Job) {
      return getJobDisplayString(value)
    } else if (value typeis PolicyPeriod) {
      return displaykey.Java.Note.PolicyPeriodLevelNote(getJobDisplayString(value.Job), value.BranchName)
    } else if (value typeis Activity) {
      return displaykey.Web.NoteSearch.CurrentActivity(value)
    } else {
      return displaykey.Note.UnknownLevel
    }
  }
  
  private static function getJobDisplayString(job : Job) : String {
    var effectiveDate = job.LatestPeriod.EditEffectiveDate
    var dateOrStatus = effectiveDate == null ? job.DisplayStatus : effectiveDate as String
    return displaykey.Java.Note.JobLevelNote(job.DisplayType, job.JobNumber, dateOrStatus)
  }
  
  /**
   * Each note securitytype (internal, sensitive, or unrestricted) is associated with zero or one permissionkey.
   * this method will be called to check that the current user has the create permission for a given securitytype.
   */
  static function hasCreatePermission(securityType : NoteSecurityType) : boolean {
    if (securityType == "internalonly") {
      return perm.System.createintnote
    } else if (securityType == "sensitive") {
      return perm.System.createsensnote
    } else {
      return true
    }
  }
  
  /**
   * Deletes the note.
   */
  function delete() {
    Transaction.runWithNewBundle(\ bundle -> {
      bundle.delete(this)
    })
  }
  
  /**
   * Completes a note.
   */
  function complete(){
    Transaction.runWithNewBundle(\ bundle -> {
      if (not StringUtils.isEmpty(this.getBody())) {
        bundle.add(this)
      }
    })
  }
  
  /** This will use the results of a template search to populate the note.
   * 
   * @param result the template result
   * @param beans the symbol table
   */
    function useTemplate(result : NoteTemplateSearchResults, beans : Map<String,Object>) {
    try {
      var locale = result.Language == null ? null : convertLanguageToLocale(result.Language)
      if (locale == null) {
        locale = LocaleUtil.getDefaultLocale()
      }
      TemplatePluginUtils.resolveTemplates( locale , 
          {new StringReader(result.Subject), new StringReader(result.Body)}, 
          // setup the symbol table for the template processing
          \ iScriptHost -> {
            for (entry in beans.entrySet()) {
              var bean = entry.getValue()
              if (bean != null) {
                iScriptHost.putSymbol(entry.Key, typeof(bean) as String, bean)
              }
            }
          }, 
          // process the result of the template expansion
          \ results -> {
            this.Topic = result.Topic
            this.Language = convertLocaleToLanguage(User.util.CurrentLocale)
            this.Subject = results[0]
            this.Body = results[1]
          } )
    } catch (e : DisplayableException) {
      var itemName = result.getName()
       throw new DisplayableException(displaykey.NoteAPI.ExceptionCaught(itemName), e)
    }
  }

  function convertLanguageToLocale(language : typekey.LanguageType) : ILocale {
    var localeTypes = LocaleType.getTypeKeys(false)
    var foundLocale = localeTypes.firstWhere(\elt1 -> elt1.Code == language.Code)
    if (foundLocale == null){
      foundLocale = localeTypes.firstWhere(\elt -> elt.Code.startsWith(language.Code))
    }
    return MetadataDependencies.getLocaleFactory().getLocaleByTypecode(foundLocale.getCode()) as ILocale
  }
  function convertLocaleToLanguage(locale : GWLocale) : LanguageType {
    var languageTypes = LanguageType.getTypeKeys(false)
    var foundLanguage = languageTypes.firstWhere(\elt1 -> elt1.Code == locale.Code)
    if (foundLanguage == null){
      foundLanguage = languageTypes .firstWhere(\elt -> locale.Code.startsWith(elt.Code))
    }
    return foundLanguage
  }

}