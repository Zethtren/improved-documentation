defmodule PhoenixDashboard.Auth do
  @moduledoc """
  Simple admin authentication backed by Bcrypt.
  Credentials are read from application config; defaults to admin/admin in dev.

  ## Configuration

  In your config:

      config :phoenix_dashboard, :admin,
        username: "admin",
        password_hash: "$2b$12$..."   # bcrypt hash

  Or for dev convenience, use a plaintext password:

      config :phoenix_dashboard, :admin,
        username: "admin",
        password: "admin"             # plaintext — checked directly

  If neither `password_hash` nor `password` is set, defaults to "admin"/"admin".
  """

  @doc "Hash a plaintext password with Bcrypt."
  def hash_password(password) when is_binary(password) do
    Bcrypt.hash_pwd_salt(password)
  end

  @doc "Verify a plaintext password against a Bcrypt hash."
  def verify_password(password, hash) when is_binary(password) and is_binary(hash) do
    Bcrypt.verify_pass(password, hash)
  end

  @doc """
  Authenticate the given `username` and `password` against
  the configured admin credentials.

  Returns `:ok` on success, `:error` on failure.
  """
  def authenticate(username, password) do
    config = Application.get_env(:phoenix_dashboard, :admin, [])

    expected_user = Keyword.get(config, :username, "admin")

    valid? =
      cond do
        # If a bcrypt hash is configured, verify against it
        hash = Keyword.get(config, :password_hash) ->
          username == expected_user and verify_password(password, hash)

        # If a plaintext password is configured (dev only), compare directly
        plain = Keyword.get(config, :password) ->
          username == expected_user and Plug.Crypto.secure_compare(password, plain)

        # Default: admin/admin
        true ->
          username == expected_user and Plug.Crypto.secure_compare(password, "admin")
      end

    if valid? do
      :ok
    else
      # Perform a dummy check to keep timing consistent
      Bcrypt.no_user_verify()
      :error
    end
  end
end
