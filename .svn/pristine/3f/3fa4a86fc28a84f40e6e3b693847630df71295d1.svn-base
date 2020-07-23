package gw.personaldata.obfuscation

uses gw.api.util.DateUtil
uses gw.plugin.personaldata.PersonalDataDestruction

@Export
abstract class UserContactLinkedObfuscator extends DefaultPersonalDataObfuscator {

  construct(bean: Obfuscatable) {
    super(bean)
  }

  abstract property get UserContact() : UserContact

  override function shouldObfuscate() : boolean {
    if (UserContact == null)
      return true

    var destructionPlugin = gw.plugin.Plugins.get(PersonalDataDestruction)
    var destructionDecision = destructionPlugin.shouldDestroyUser(UserContact)
    if (destructionDecision == MUST_NOT_DESTROY) {
      var title = displaykey.PersonalData.NotifyProtectionOfficer.Obfuscation.MustNotDestroy.Title(UserContact.IntrinsicType.RelativeName, UserContact.DisplayName)
      var message = displaykey.PersonalData.NotifyProtectionOfficer.Obfuscation.MustNotDestroy.Message(UserContact.IntrinsicType, UserContact.DisplayName, UserContact)
      destructionPlugin.notifyDataProtectionOfficer(UserContact, title, message, DateUtil.currentDate())
      return false
    }

    return true
  }
}