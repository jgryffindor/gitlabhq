---
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# SAML SSO for GitLab.com groups **(PREMIUM SAAS)**

> Introduced in GitLab 11.0.

Users can sign in to GitLab through their SAML identity provider.

[SCIM](scim_setup.md) synchronizes users with the group on GitLab.com.

- When you add or remove a user from the SCIM app, SCIM adds or removes the user
  from the GitLab group.
- If the user is not already a group member, the user is added to the group as part of the sign-in process.

You can configure SAML SSO for the top-level group only.

## Configure your identity provider

1. Find the information in GitLab required for configuration:
   1. On the top bar, select **Main menu > Groups** and find your group.
   1. On the left sidebar, select **Settings > SAML SSO**.
   1. Note the **Assertion consumer service URL**, **Identifier**, and **GitLab single sign-on URL**.
1. Configure your SAML identity provider app using the noted details.
   Alternatively, GitLab provides a [metadata XML configuration](#metadata-configuration).
   See [specific identity provider documentation](#set-up-identity-provider) for more details.
1. Configure the SAML response to include a [NameID](#nameid) that uniquely identifies each user.
1. Configure the required [user attributes](#user-attributes), ensuring you include the user's email address.
1. While the default is enabled for most SAML providers, ensure the app is set to have service provider
   initiated calls to link existing GitLab accounts.
1. Once the identity provider is set up, move on to [configuring GitLab](#configure-gitlab).

![Issuer and callback for configuring SAML identity provider with GitLab.com](img/group_saml_configuration_information.png)

If your account is the only owner in the group after SAML is set up, you can't unlink the account. To [unlink the account](#unlinking-accounts),
set up another user as a group owner.

## Set up identity provider

The SAML standard means that you can use a wide range of identity providers with GitLab. Your identity provider might have relevant documentation. It can be generic SAML documentation or specifically targeted for GitLab.

When [configuring your identity provider](#configure-your-identity-provider), consider the notes below for specific providers to help avoid common issues and as a guide for terminology used.

For providers not listed below, you can refer to the [instance SAML notes on configuring an identity provider](../../../integration/saml.md#configure-saml-on-your-idp)
for additional guidance on information your identity provider may require.

GitLab provides the following information for guidance only.
If you have any questions on configuring the SAML app, contact your provider's support.

### Set up Azure

1. [Use Azure to configure SSO for an application](https://learn.microsoft.com/en-us/azure/active-directory/manage-apps/add-application-portal-setup-sso). The following GitLab settings correspond to the Azure fields.

   | GitLab setting                       | Azure field                                |
   | ------------------------------------ | ------------------------------------------ |
   | Identifier                           | Identifier (Entity ID)                     |
   | Assertion consumer service URL       | Reply URL (Assertion Consumer Service URL) |
   | GitLab single sign-on URL            | Sign on URL                                |
   | Identity provider single sign-on URL | Login URL                                  |
   | Certificate fingerprint              | Thumbprint                                 |

1. You should set the following attributes:
   - **Unique User Identifier (Name identifier)** to `user.objectID`.
   - **nameid-format** to persistent.
   - **Additional claims** to [supported attributes](#user-attributes).

1. Optional. If you use [Group Sync](#group-sync), customize the name of the
   group claim to match the required attribute.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
View a demo of [SCIM provisioning on Azure using SAML SSO for groups](https://youtu.be/24-ZxmTeEBU). The `objectID` mapping is outdated in this video. Follow the [SCIM documentation](scim_setup.md#configure-azure-active-directory) instead.

View an [example configuration page](example_saml_config.md#azure-active-directory).

### Set up Google Workspace

1. [Set up SSO with Google as your identity provider](https://support.google.com/a/answer/6087519?hl=en).
   The following GitLab settings correspond to the Google Workspace fields.

   | GitLab setting                       | Google Workspace field |
   |:-------------------------------------|:-----------------------|
   | Identifier                           | **Entity ID**          |
   | Assertion consumer service URL       | **ACS URL**            |
   | GitLab single sign-on URL            | **Start URL**          |
   | Identity provider single sign-on URL | **SSO URL**            |

1. Google Workspace displays a SHA256 fingerprint. To retrieve the SHA1 fingerprint
   required by GitLab to [configure SAML](#configure-gitlab):
   1. Download the certificate.
   1. Run this command:

      ```shell
      openssl x509 -noout -fingerprint -sha1 -inform pem -in "GoogleIDPCertificate-domain.com.pem"
      ```

1. Set these values:
   - For **Primary email**: `email`
   - For **First name**: `first_name`
   - For **Last name**: `last_name`
   - For **Name ID format**: `EMAIL`
   - For **NameID**: `Basic Information > Primary email`

On the GitLab SAML SSO page, when you select **Verify SAML Configuration**, disregard
the warning that recommends setting the **NameID** format to `persistent`.

For details, see the [example configuration page](example_saml_config.md#google-workspace).

### Set up Okta

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For a demo of the Okta SAML setup including SCIM, see [Demo: Okta Group SAML & SCIM setup](https://youtu.be/0ES9HsZq0AQ).

1. [Set up a SAML application in Okta](https://developer.okta.com/docs/guides/build-sso-integration/saml2/main/).
   The following GitLab settings correspond to the Okta fields.

   | GitLab setting                       | Okta field                                                 |
   | ------------------------------------ | ---------------------------------------------------------- |
   | Identifier                           | **Audience URI**                                               |
   | Assertion consumer service URL       | **Single sign-on URL**                                         |
   | GitLab single sign-on URL            | **Login page URL** (under **Application Login Page** settings) |
   | Identity provider single sign-on URL | **Identity Provider Single Sign-On URL**                       |

1. Under the Okta **Single sign-on URL** field, select the **Use this for Recipient URL and Destination URL** checkbox.

1. Set these values:
   - For **Application username (NameID)**: **Custom** `user.getInternalProperty("id")`
   - For **Name ID Format**: `Persistent`

The Okta GitLab application available in the App Catalog only supports [SCIM](scim_setup.md). Support
for SAML is proposed in [issue 216173](https://gitlab.com/gitlab-org/gitlab/-/issues/216173).

### Set up OneLogin

OneLogin supports its own [GitLab (SaaS) application](https://onelogin.service-now.com/support?id=kb_article&sys_id=92e4160adbf16cd0ca1c400e0b961923&kb_category=50984e84db738300d5505eea4b961913).

1. If you use the OneLogin generic
   [SAML Test Connector (Advanced)](https://onelogin.service-now.com/support?id=kb_article&sys_id=b2c19353dbde7b8024c780c74b9619fb&kb_category=93e869b0db185340d5505eea4b961934),
   you should [use the OneLogin SAML Test Connector](https://onelogin.service-now.com/support?id=kb_article&sys_id=93f95543db109700d5505eea4b96198f). The following GitLab settings correspond
   to the OneLogin fields:

   | GitLab setting                                   | OneLogin field                   |
   | ------------------------------------------------ | -------------------------------- |
   | Identifier                                       | **Audience**                     |
   | Assertion consumer service URL                   | **Recipient**                    |
   | Assertion consumer service URL                   | **ACS (Consumer) URL**           |
   | Assertion consumer service URL (escaped version) | **ACS (Consumer) URL Validator** |
   | GitLab single sign-on URL                        | **Login URL**                    |
   | Identity provider single sign-on URL             | **SAML 2.0 Endpoint**            |

1. For **NameID**, use `OneLogin ID`.

### NameID

GitLab.com uses the SAML NameID to identify users. The NameID element:

- Is a required field in the SAML response.
- Must be unique to each user.
- Must be a persistent value that never changes, such as a randomly generated unique user ID.
- Is case sensitive. The NameID must match exactly on subsequent login attempts, so should not rely on user input that could change between upper and lower case.
- Should not be an email address or username. We strongly recommend against these as it's hard to
  guarantee it doesn't ever change, for example, when a person's name changes. Email addresses are
  also case-insensitive, which can result in users being unable to sign in.

The relevant field name and recommended value for supported providers are in the [provider specific notes](#set-up-identity-provider).

WARNING:
Once users have signed into GitLab using the SSO SAML setup, changing the `NameID` breaks the configuration and potentially locks users out of the GitLab group.

#### NameID Format

We recommend setting the NameID format to `Persistent` unless using a field (such as email) that requires a different format.
Most NameID formats can be used, except `Transient` due to the temporary nature of this format.

### User attributes

To create users with the correct information for improved [user access and management](#user-access-and-management),
the user's details must be passed to GitLab as attributes in the SAML assertion. At a minimum, the user's email address
must be specified as an attribute named `email` or `mail`.

You can configure the following attributes with GitLab.com Group SAML:

- `username` or `nickname`. We recommend you configure only one of these.
- The [attributes available](../../../integration/saml.md#configure-assertions) to self-managed GitLab instances.

### Metadata configuration

GitLab provides metadata XML that can be used to configure your identity provider.

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Settings > SAML SSO**.
1. Copy the provided **GitLab metadata URL**.
1. Follow your identity provider's documentation and paste the metadata URL when it's requested.

## Configure GitLab

After you set up your identity provider to work with GitLab, you must configure GitLab to use it for authentication:

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Settings > SAML SSO**.
1. Find the SSO URL from your identity provider and enter it the **Identity provider single sign-on URL** field.
1. Find and enter the fingerprint for the SAML token signing certificate in the **Certificate** field.
1. Select the access level to be applied to newly added users in the **Default membership role** field. The default access level is 'Guest'.
1. Select the **Enable SAML authentication for this group** checkbox.
1. Select the **Save changes** button.

![Group SAML Settings for GitLab.com](img/group_saml_settings_v13_12.png)

NOTE:
The certificate [fingerprint algorithm](../../../integration/saml.md#configure-saml-on-your-idp) must be in SHA1. When configuring the identity provider (such as [Google Workspace](#set-up-google-workspace)), use a secure signature algorithm.

### Additional configuration information

Many SAML terms can vary between providers. It is possible that the information you are looking for is listed under another name.

For more information, start with your identity provider's documentation. Look for their options and examples to see how they configure SAML. This can provide hints on what you need to configure GitLab to work with these providers.

It can also help to look at our [more detailed docs for self-managed GitLab](../../../integration/saml.md).
SAML configuration for GitLab.com is mostly the same as for self-managed instances.
However, self-managed GitLab instances use a configuration file that supports more options as described in the external [OmniAuth SAML documentation](https://github.com/omniauth/omniauth-saml/).
Internally that uses the [`ruby-saml` library](https://github.com/onelogin/ruby-saml), so we sometimes check there to verify low level details of less commonly used options.

It can also help to compare the XML response from your provider with our [example XML used for internal testing](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/spec/fixtures/saml/response.xml).

### SSO enforcement

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/5291) in GitLab 11.8.
> - [Improved](https://gitlab.com/gitlab-org/gitlab/-/issues/9255) in GitLab 11.11 with ongoing enforcement in the GitLab UI.
> - [Improved](https://gitlab.com/gitlab-org/gitlab/-/issues/292811) in GitLab 13.8, with an updated timeout experience.
> - [Improved](https://gitlab.com/gitlab-org/gitlab/-/issues/211962) in GitLab 13.8 with allowing group owners to not go through SSO.
> - [Improved](https://gitlab.com/gitlab-org/gitlab/-/issues/9152) in GitLab 13.11 with enforcing open SSO session to use Git if this setting is switched on.
> - [Improved](https://gitlab.com/gitlab-org/gitlab/-/issues/339888) in GitLab 14.7 to not enforce SSO checks for Git activity originating from CI/CD jobs.
> - [Improved](https://gitlab.com/gitlab-org/gitlab/-/issues/215155) in GitLab 15.5 [with a flag](../../../administration/feature_flags.md) named `transparent_sso_enforcement` to include transparent enforcement even when SSO enforcement is not enabled. Disabled on GitLab.com.
> - [Improved](https://gitlab.com/gitlab-org/gitlab/-/issues/375788) in GitLab 15.8 by enabling transparent SSO by default on GitLab.com.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/389562) in GitLab 15.10. Feature flag `transparent_sso_enforcement` removed.

On GitLab.com, SSO is enforced:

- When SAML SSO is enabled.
- For users with an existing SAML identity when accessing groups and projects in the organization's
  group hierarchy. Users can view other groups and projects as well as their user settings without SSO sign in by using their GitLab.com credentials.

A user has a SAML identity if one or both of the following are true:

- They have signed in to GitLab by using their GitLab group's single sign-on URL.
- They were provisioned by SCIM.

Users are not prompted to sign in through SSO on each visit. GitLab checks
whether a user has authenticated through SSO. If the user last signed in more
than 24 hours ago, GitLab prompts the user to sign in again through SSO.

SSO is enforced as follows:

| Project/Group visibility | Enforce SSO setting | Member with identity | Member without identity | Non-member or not signed in |
|--------------------------|---------------------|--------------------| ------ |------------------------------|
| Private                  | Off                 | Enforced           | Not enforced | No access                    |
| Private                  | On            | Enforced           | Enforced | No access                    |
| Public                   | Off                 | Enforced           | Not enforced | Not enforced                 |
| Public                   | On            | Enforced           | Enforced | Not enforced                 |

An [issue exists](https://gitlab.com/gitlab-org/gitlab/-/issues/297389) to add a similar SSO requirement for API activity.

#### SSO-only for web activity enforcement

When the **Enforce SSO-only authentication for web activity for this group** option is enabled:

- All users must access GitLab by using their GitLab group's single sign-on URL
  to access group resources, regardless of whether they have an existing SAML
  identity.
- SSO is enforced when users access groups and projects in the organization's
  group hierarchy. Users can view other groups and projects without SSO sign in.
- Users cannot be added as new members manually.
- Users with the Owner role can use the standard sign in process to make
  necessary changes to top-level group settings.

SSO enforcement for web activity has the following effects when enabled:

- For groups, users cannot share a project in the group outside the top-level
  group, even if the project is forked.
- Git activity originating from CI/CD jobs do not have the SSO check enforced.
- Credentials that are not tied to regular users (for example, project and group
  access tokens, and deploy keys) do not have the SSO check enforced.
- Users must be signed-in through SSO before they can pull images using the
  [Dependency Proxy](../../packages/dependency_proxy/index.md).
- When the **Enforce SSO-only authentication for Git and Dependency Proxy
  activity for this group** option is enabled, any API endpoint that involves
  Git activity is under SSO enforcement. For example, creating or deleting a
  branch, commit, or tag. For Git activity over SSH and HTTPS, users must
  have at least one active session signed-in through SSO before they can push to or
  pull from a GitLab repository.

When SSO for web activity is enforced, non-SSO group members do not lose access
immediately. If the user:

- Has an active session, they can continue accessing the group for up to 24
  hours until the identity provider session times out.
- Is signed out, they cannot access the group after being removed from the
  identity provider.

### Change the SAML app

After you have configured your identity provider, you can:

- Change the identity provider users sign in with.
- Migrate to a different identity provider.
- Change email domains.

### Change the identity provider

To change the identity provider:

- If the `NameID` is not identical in the existing and new identity providers, [change the NameID for users](#change-nameid-for-one-or-more-users).
- If the `NameID` is identical, users do not have to make any changes.

### Migrate to a different identity provider

You can migrate to a different identity provider. During the migration process,
users cannot access any of the SAML groups. To mitigate this, you can disable
[SSO enforcement](#sso-enforcement).

To migrate identity providers:

1. [Configure](#configure-your-identity-provider) the group with the new identity provider.
1. [Change the NameID for users](#change-nameid-for-one-or-more-users).

### Change email domains

To migrate users to a new email domain, tell users to:

1. Add their new email as the primary email to their accounts and verify it.
1. Optional. Remove their old email from the account.

If the NameID is configured with the email address, [change the NameID for users](#change-nameid-for-one-or-more-users).

## User access and management

> - SAML user provisioning [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/268142) in GitLab 13.7.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/325712) in GitLab 14.0, GitLab users created by [SAML SSO](index.md#user-access-and-management) or SCIM provisioning are displayed with an ][**Enterprise**](../../enterprise_user/index.md) badge in the **Members** view.

After group SSO is configured and enabled, users can access the GitLab.com group through the identity provider's dashboard.
If [SCIM](scim_setup.md) is configured, see [user access](scim_setup.md#user-access) on the SCIM page.

When a user tries to sign in with Group SSO, GitLab attempts to find or create a user based on the following:

- Find an existing user with a matching SAML identity. This would mean the user either had their account created by [SCIM](scim_setup.md) or they have previously signed in with the group's SAML IdP.
- If there is no conflicting user with the same email address, create a new account automatically.
- If there is a conflicting user with the same email address, redirect the user to the sign-in page to:
  - Create a new account with another email address.
  - Sign-in to their existing account to link the SAML identity.

### Linking SAML to your existing GitLab.com account

> **Remember me** checkbox [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/121569) in GitLab 15.7.

To link SAML to your existing GitLab.com account:

1. Sign in to your GitLab.com account. [Reset your password](https://gitlab.com/users/password/new) if necessary.
1. Locate and visit the **GitLab single sign-on URL** for the group you're signing in to. A group owner can find this on the group's **Settings > SAML SSO** page. If the sign-in URL is configured, users can connect to the GitLab app from the identity provider.
1. Optional. Select the **Remember me** checkbox to stay signed in to GitLab for 2 weeks. You may still be asked to re-authenticate with your SAML provider
   more frequently.
1. Select **Authorize**.
1. Enter your credentials on the identity provider if prompted.
1. You are then redirected back to GitLab.com and should now have access to the group. In the future, you can use SAML to sign in to GitLab.com.

On subsequent visits, you should be able to go [sign in to GitLab.com with SAML](#signing-in-to-gitlabcom-with-saml) or by visiting links directly. If the **enforce SSO** option is turned on, you are then redirected to sign in through the identity provider.

### Signing in to GitLab.com with SAML

1. Sign in to your identity provider.
1. From the list of apps, select the "GitLab.com" app. (The name is set by the administrator of the identity provider.)
1. You are then signed in to GitLab.com and redirected to the group.

### Change NameID for one or more users

> Update of SAML identities using the SAML API [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/227841) in GitLab 15.5.

Group owners can update the SAML identities for their group members using the [SAML API](../../../api/saml.md#update-extern_uid-field-for-a-saml-identity).
If [SCIM](scim_setup.md) is configured, group owners can update the SCIM identities using the [SCIM API](../../../api/scim.md#update-extern_uid-field-for-a-scim-identity).

Alternatively, ask the users to reconnect their SAML account.

1. Ask relevant users to [unlink their account from the group](#unlinking-accounts).
1. Ask relevant users to [link their account to the new SAML app](#linking-saml-to-your-existing-gitlabcom-account).

### Configure user settings from SAML response

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/263661) in GitLab 13.7.

GitLab allows setting certain user attributes based on values from the SAML response.
Existing users will have these attributes updated if the user was originally
provisioned by the group. Users are provisioned by the group when the account was
created via [SCIM](scim_setup.md) or by first sign-in with SAML SSO for GitLab.com groups.

#### Supported user attributes

- `can_create_group` - 'true' or 'false' to indicate whether the user can create
  new groups. Default is `true`.
- `projects_limit` - The total number of personal projects a user can create.
  A value of `0` means the user cannot create new projects in their personal
  namespace. Default is `10000`.

#### Example SAML response

You can find SAML responses in the developer tools or console of your browser,
in base64-encoded format. Use the base64 decoding tool of your choice to
convert the information to XML. An example SAML response is shown here.

```xml
   <saml2:AttributeStatement>
      <saml2:Attribute Name="email" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
         <saml2:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">user.email</saml2:AttributeValue>
      </saml2:Attribute>
      <saml2:Attribute Name="username" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
        <saml2:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">user.nickName</saml2:AttributeValue>
      </saml2:Attribute>
      <saml2:Attribute Name="first_name" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified">
         <saml2:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">user.firstName</saml2:AttributeValue>
      </saml2:Attribute>
      <saml2:Attribute Name="last_name" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified">
         <saml2:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">user.lastName</saml2:AttributeValue>
      </saml2:Attribute>
      <saml2:Attribute Name="can_create_group" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified">
         <saml2:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">true</saml2:AttributeValue>
      </saml2:Attribute>
      <saml2:Attribute Name="projects_limit" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified">
         <saml2:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">10</saml2:AttributeValue>
      </saml2:Attribute>
   </saml2:AttributeStatement>
```

### Bypass user email confirmation with verified domains

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/238461) in GitLab 15.4.

By default, users provisioned with SAML or SCIM are sent a verification email to verify their identity. Instead, you can
[configure GitLab with a custom domain](../../project/pages/custom_domains_ssl_tls_certification/index.md) and GitLab
automatically confirms user accounts. Users still receive an
[enterprise user](../../enterprise_user/index.md) welcome email. Confirmation is
bypassed for users:

- That are provisioned with SAML or SCIM.
- That have an email address that belongs to the verified domain.

### Role

Starting from [GitLab 13.3](https://gitlab.com/gitlab-org/gitlab/-/issues/214523), group owners can set a
"Default membership role" other than Guest. To do so, [configure the SAML SSO for the group](#configure-gitlab).
That role becomes the starting access level of all users added to the group.

Existing members with appropriate privileges can promote or demote users, as needed.

If a user is already a member of the group, linking the SAML identity does not change their role.

Users given a "minimal access" role have [specific restrictions](../../permissions.md#users-with-minimal-access).

### Blocking access

To rescind a user's access to the group when only SAML SSO is configured, either:

- Remove (in order) the user from:
  1. The user data store on the identity provider or the list of users on the specific app.
  1. The GitLab.com group.
- Use [Group Sync](group_sync.md#automatic-member-removal) at the top-level of your group with the [default role](#role) set to [minimal access](../../permissions.md#users-with-minimal-access) to automatically block access to all resources within the group. Users may continue to [use a seat](../../permissions.md#minimal-access-users-take-license-seats).

To rescind a user's access to the group when also using SCIM, refer to [Remove access](scim_setup.md#remove-access).

### Unlinking accounts

Users can unlink SAML for a group from their profile page. This can be helpful if:

- You no longer want a group to be able to sign you in to GitLab.com.
- Your SAML NameID has changed and so GitLab can no longer find your user.

WARNING:
Unlinking an account removes all roles assigned to that user in the group.
If a user re-links their account, roles need to be reassigned.

Groups require at least one owner. If your account is the only owner in the
group, you are not allowed to unlink the account. In that case, set up another user as a
group owner, and then you can unlink the account.

For example, to unlink the `MyOrg` account:

1. On the top bar, in the upper-right corner, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Account**.
1. In the **Service sign-in** section, select **Disconnect** next to the connected account.

## Group Sync

For information on automatically managing GitLab group membership, see [SAML Group Sync](group_sync.md).

## Passwords for users created via SAML SSO for Groups

The [Generated passwords for users created through integrated authentication](../../../security/passwords_for_integrated_authentication_methods.md) guide provides an overview of how GitLab generates and sets passwords for users created via SAML SSO for Groups.

## Related topics

For more information on:

- Setting up SAML on self-managed GitLab instances, see
  [SAML SSO for self-managed GitLab instances](../../../integration/saml.md).
- Commonly-used terms, see the
  [glossary of common terms](../../../integration/saml.md#glossary-of-common-terms).
- The differences between SaaS and self-managed authentication and authorization,
  see the [SaaS vs. Self-Managed comparison](../../../administration/auth/index.md#saas-vs-self-managed-comparison).

## Troubleshooting

See our [troubleshooting SAML guide](troubleshooting.md).
