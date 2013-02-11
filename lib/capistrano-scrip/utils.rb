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

def create_remote_dir(dir)
  commands = []
  commands << "mkdir -p #{dir}"
  commands << "chown #{user}:#{group} #{dir} -R"
  commands << "chmod +rw #{dir}"

  run commands.join(" && ")
end

# Returns true if remote file exists
def remote_file_exists?(full_path)
  'true' ==  capture("if [ -e #{full_path} ]; then echo 'true'; fi").strip
end

# Generates a configuration file parsing through ERB template and uploads to remote_file
# Make sure your user has the right permissions.
def generate_config(template, remote_file)
  unless File.exists?(path = template) ||
      File.exists?(path = File.join('config', 'deploy', 'templates', template)) ||
      File.exists?(path = File.join(File.expand_path('../../../templates', __FILE__), template))
    abort("Template not found: #{template}")
  end
  logger.info "Uploading template #{path} to #{remote_file}"
  run "mkdir -p #{File.dirname(remote_file)}"
  upload StringIO.new(ERB.new(File.read(path)).result(binding)), remote_file
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
