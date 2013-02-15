require 'capistrano-scrip/utils'

# RVM (Ruby Version Manager)-related tasks
# @deprecated This tasks are untested and most likely don't work
Capistrano::Configuration.instance.load do
  namespace :rvm do
    desc "Installs rvm on target machine"
    task :install_rvm do
      run "#{sudo} #{rvm_install_shell} -s #{rvm_install_type} \
< <(curl -s https://raw.github.com/wayneeseguin/rvm/master/binscripts/rvm-installer)", :shell => "#{rvm_install_shell}"
    end

    desc "Installs ruby on target machine (via RVM)"
    task :install_ruby do
      ruby, gemset = rvm_ruby_string.to_s.strip.split /@/
      if %w( release_path default ).include? "#{ruby}"
        raise "ruby can not be installed when using :rvm_ruby_string => :#{ruby}"
      else
        run "#{sudo} #{File.join(rvm_bin_path, "rvm")} #{rvm_install_ruby} #{ruby} -j #{rvm_install_ruby_threads}", :shell => "#{rvm_install_shell}"
        if gemset
          run "#{sudo} #{File.join(rvm_bin_path, "rvm")} #{ruby} do rvm gemset create #{gemset}", :shell => "#{rvm_install_shell}"
        end
      end
    end

    desc "Cretaes rvm gemset (must be run after +rvm:install_ruby+)"
    task :create_gemset do
      ruby, gemset = rvm_ruby_string.to_s.strip.split /@/
      if %w( release_path default ).include? "#{ruby}"
        raise "gemset can not be created when using :rvm_ruby_string => :#{ruby}"
      else
        if gemset
          run "#{File.join(rvm_bin_path, "rvm")} #{ruby} do rvm gemset create #{gemset}", :shell => "#{rvm_install_shell}"
        end
      end
    end
  end
end
