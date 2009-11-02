module Rails
  module Generator
    module Options
      def add_general_options!(opt)
        opt.separator ''
        opt.separator 'Rails Info:'
        opt.on('-v', '--version', 'Show the Rails version number and quit.')
        opt.on('-h', '--help', 'Show this help message and quit.') { |v| options[:help] = v }

        opt.separator ''
        opt.separator 'General Options:'

        opt.on('-p', '--pretend', 'Run but do not make any changes.') { |v| options[:pretend] = v }
        opt.on('-f', '--force', 'Overwrite files that already exist.') { options[:collision] = :force }
        opt.on('-s', '--skip', 'Skip files that already exist.') { options[:collision] = :skip }
        opt.on('-q', '--quiet', 'Suppress normal output.') { |v| options[:quiet] = v }
        opt.on('-t', '--backtrace', 'Debugging: show backtrace on errors.') { |v| options[:backtrace] = v }
        opt.on('-c', '--svn', 'Modify files with subversion. (Note: svn must be in path)') do
          options[:svn] = {}
          `svn status`.each_line do |line|
            options[:svn][line.chomp[7..-1]] = true
          end
        end
        opt.on('-g', '--git', 'Modify files with git. (Note: git must be in path)') do
          options[:git] = {:new => {}, :modified => {}}
          `git status`.each_line do |line|
            options[:git][:new][line.chomp[14..-1]] = true if line =~ /new file:/
            options[:git][:modified][line.chomp[14..-1]] = true if line =~ /modified:/
          end
        end
      end
    end
  end
end