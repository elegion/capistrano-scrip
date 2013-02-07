def _cset(variable, *args, &block)
  set(variable, *args, &block) unless exists?(variable)
end

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

# Generates a configuration file parsing through ERB template and uploads to remote_file
# Make sure your user has the right permissions.
def generate_config(template, remote_file)
  upload StringIO.new(ERB.new(File.read(template)).result(binding)), remote_file
end

def ask_with_default(var, default)
  set(var) do
    Capistrano::CLI.ui.ask "#{var} [#{default}] : "
  end
  set var, default if eval("#{var.to_s}.empty?")
end

def password_prompt_with_default(var, default)
  set(var) do
    Capistrano::CLI.password_prompt "#{var} [#{default}] : "
  end
  set var, default if eval("#{var.to_s}.empty?")
end
