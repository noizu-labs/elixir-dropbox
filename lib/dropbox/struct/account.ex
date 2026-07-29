defmodule Noizu.Dropbox.Struct.Account do
  @moduledoc "Basic / full account info from `users/*`."

  @type t :: %__MODULE__{
          account_id: String.t() | nil,
          name: map() | nil,
          email: String.t() | nil,
          email_verified: boolean() | nil,
          disabled: boolean() | nil,
          is_teammate: boolean() | nil,
          profile_photo_url: String.t() | nil,
          country: String.t() | nil,
          locale: String.t() | nil,
          referral_link: String.t() | nil,
          is_paired: boolean() | nil,
          account_type: String.t() | nil,
          root_info: map() | nil,
          team: map() | nil,
          team_member_id: String.t() | nil,
          raw: map()
        }

  defstruct [
    :account_id,
    :name,
    :email,
    :email_verified,
    :disabled,
    :is_teammate,
    :profile_photo_url,
    :country,
    :locale,
    :referral_link,
    :is_paired,
    :account_type,
    :root_info,
    :team,
    :team_member_id,
    :raw
  ]

  def from_json(nil), do: nil
  def from_json(list) when is_list(list), do: Enum.map(list, &from_json/1)

  def from_json(%{} = json) do
    account_type =
      case json[:account_type] || json["account_type"] do
        %{".tag": tag} -> tag
        %{".tag" => tag} -> tag
        other -> other
      end

    %__MODULE__{
      account_id: json[:account_id] || json["account_id"],
      name: json[:name] || json["name"],
      email: json[:email] || json["email"],
      email_verified: json[:email_verified] || json["email_verified"],
      disabled: json[:disabled] || json["disabled"],
      is_teammate: json[:is_teammate] || json["is_teammate"],
      profile_photo_url: json[:profile_photo_url] || json["profile_photo_url"],
      country: json[:country] || json["country"],
      locale: json[:locale] || json["locale"],
      referral_link: json[:referral_link] || json["referral_link"],
      is_paired: json[:is_paired] || json["is_paired"],
      account_type: account_type,
      root_info: json[:root_info] || json["root_info"],
      team: json[:team] || json["team"],
      team_member_id: json[:team_member_id] || json["team_member_id"],
      raw: json
    }
  end
end
