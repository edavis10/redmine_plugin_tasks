# module: redmine_plugin_tasks
module RedminePluginTasks
  class Base < Thor
    include Thor::Actions

    def self.source_root
      File.dirname(__FILE__)
    end
  end

  class Docs < Base
    desc "gpl2", "generate the GPLv2 license"
    def gpl2
      copy_file 'templates/GPL.txt', "GPL.txt"
    end
  end
end

