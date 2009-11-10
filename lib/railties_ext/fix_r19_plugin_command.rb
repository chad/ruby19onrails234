class Plugin
  def install_using_git(options = {})
    root = rails_env.root
    mkdir_p(install_path = "#{root}/vendor/plugins/#{name}")
    Dir.chdir install_path do
      init_cmd = "git init"
      init_cmd += " -q" if options[:quiet] and not $verbose
      puts init_cmd if $verbose
      system(init_cmd)
      base_cmd = "git pull --depth 1 #{uri}"
      base_cmd += " -q" if options[:quiet] and not $verbose
      base_cmd += " #{options[:revision]}" if options[:revision]
      puts base_cmd if $verbose
      if system(base_cmd)
        puts "removing: .git .gitignore" if $verbose
        rm_rf %w(.git .gitignore)
      else
        rm_rf install_path
      end
    end
  end
end