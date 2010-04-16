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

    desc "copyright", "generate a copyright file (GPL2)"
    def copyright
      @description = ask("What is your program and what does it do?")
      @copyright_holder = ask("Who is the copyright holder?")

      template("templates/COPYRIGHT.erb", "COPYRIGHT.txt")
    end

    desc "credits", "generate a Credits file"
    def credits
      @people = []
      while yes?("Add a person?", :green)
        add_person(@people)
      end

      template("templates/CREDITS.erb", "CREDITS.txt")

    end

    desc "readme", "generate a Readme"
    def readme
      @plugin_name = ask("What is the plugin name?")
      @plugin_description = ask("What does the plugin do?")
      @redmine_project = ask("What is the Redmine project identifier?")
      @github_repo = ask("What is the Github repo called?")
      
      template("templates/README.rdoc.erb", "README.rdoc")
    end
    
    private
    
    def add_person(people)
      name = ask("What is their name?")
      role = ask("What is their role in the project?")
      people << {:name => name, :role => role}
      people
    end
  end
end

