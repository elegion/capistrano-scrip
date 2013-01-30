def with_user(new_user, &block)
  old_user = user
  if old_user != new_user
    set :user, new_user
    teardown_connections_to(sessions.keys)
  end

  yield

  if old_user != new_user
    set :user, old_user
    teardown_connections_to(sessions.keys)
  end
end
