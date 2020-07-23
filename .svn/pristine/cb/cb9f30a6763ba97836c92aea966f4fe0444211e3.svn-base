package gw.web.admin

uses gw.api.system.ExternalUserAccessParameterKey
uses gw.api.util.DisplayableException
uses gw.pc.community.entity.GroupCoreExt

@Export
class UserUIHelper {
  public static function verifyAttributeNameIsUnique(currentAttr: AttributeUser, attributes: List) : String {
    for (value in attributes) {
      var attribute = (value as AttributeUser)
      if (attribute != currentAttr
          and attribute.Attribute.Name == currentAttr.Attribute.Name
          and attribute.Attribute.Type == currentAttr.Attribute.Type) {
        return displaykey.Web.Admin.UserAttributes.DuplicateName(currentAttr.Attribute.Name)
      }
    }
    return null
  }

  public static function initialGroups(pc : ProducerCode, u : User) : Group[] {
    var groupsSet = pc.getAllGroups()
    groupsSet.retainAll( u.getAllGroups())
    var groupsList = groupsSet.whereTypeIs( Group ).toList().sort()
    return groupsList.toTypedArray()
  }

  public static function isNotLastEntry(groups : Group[], grp : Group) : Boolean {
    return groups.last() != grp
  }

  public static function shouldShowConfirmMessageWhenSwitchingBetweenInternalAndExternalUsers(user : entity.User) : Boolean {
    var externalUser = user.ExternalUser
    if (!externalUser) {
      return user.AllGroupUsersAsArray.Count > 0
    }
    return user.AllGroupUsersAsArray.Count > 0 or user.Organization != null
  }

  public static function initializeUserSearchCriteria() : UserSearchCriteria {
    var rtn = new UserSearchCriteria()
    if (User.util.CurrentUser.ExternalUser) {
      rtn.Organization = User.util.CurrentUser.Organization
    }
    return rtn
  }

  public static function validateAndAddGroup(group : Group, user : User) : GroupUser {
    if (group.canAllowExternalAccess(user)) {
      var groupUser = new GroupUser()
      groupUser.User = user
      group.addToUsers(groupUser)
      user.addToGroup(groupUser)
      return groupUser
    } else {
      throw new DisplayableException(displaykey.Web.Admin.GroupUsers.AddInvalidGroup(group.Name, user.DisplayName))
    }
  }

  public static function createSearchCriteria(organization : Organization, userType : UserType) : UserSearchCriteria {
    var c = new UserSearchCriteria()
    var CurrentUser = User.util.CurrentUser
    if (ExternalUserAccessParameterKey.ExternalUserAccessIsFullyRestricted() and CurrentUser.ExternalUser) {
      c.Organization = CurrentUser.Organization
    }
    else {
      c.Organization = organization
    }
    c.UserType = userType
    return c
  }
}