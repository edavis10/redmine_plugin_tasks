# module: redmine_plugin_tasks
module RedminePluginTasks
  class Base < Thor
    include Thor::Actions

    def self.source_root
      File.dirname(__FILE__)
    end
  end

  class Docs < Base
    desc "all", "Generate all docs for a new plugin"
    def all
      ask_basic_questions

      invoke :gpl2
      invoke :copyright
      invoke :credits
      invoke :readme
      invoke :rakefile
    end

    desc "gpl2", "generate the GPLv2 license"
    def gpl2
      copy_file 'templates/GPL.txt', "GPL.txt"
    end

    desc "copyright", "generate a copyright file (GPL2)"
    def copyright
      ask_basic_questions
      @description = @plugin_name + ' is a plugin that ' + @plugin_short_description
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
      ask_basic_questions
      template("templates/README.rdoc.erb", "README.rdoc")
    end

    desc "rakefile", "generate a Rakefile"
    def rakefile
      ask_basic_questions
      template("templates/Rakefile.erb", "Rakefile")
    end
    
    private

    def ask_basic_questions
      @plugin_name ||= ask("What is the plugin name?")
      @plugin_short_description ||= ask("What does the plugin do (short)?")
      @plugin_description ||= ask("What does the plugin do (long)?")
      @copyright_holder ||= ask("Who is the copyright holder?")
      @redmine_project ||= ask("What is the Redmine project identifier?")
      @github_repo ||= ask("What is the Github repo called?")
    end
    
    def add_person(people)
      name = ask("What is their name?")
      role = ask("What is their role in the project?")
      people << {:name => name, :role => role}
      people
    end
  end
end

