begin
  require 'rest-client' if Puppet.features.rest_client?
  require 'json' if Puppet.features.json?   
  require 'uri'       # TODO FEATURE
  require 'fileutils' # TODO FEATURE
rescue LoadError => e
  Puppet.info "Gerrit Puppet module requires 'rest-client' and 'json' ruby gems."
end

class Puppet::Provider::Git < Puppet::Provider::Rest
  desc "Gerrit Projects Git Config"

  confine :feature => :json
  confine :feature => :rest_client  
  
  # TODO VERY STRANGE ERROR - commands :git => 'git'
  
  def self.gitcmd(*args) 
    argList = ""
    args.each do |arg|
      argList += " "+arg
    end
        
    %x{git #{argList}}
  end
  
  def self.get_path(warn = false)
    parent = '/opt/gerrit'        # TODO PARAM rest_info ?
    if (! File.directory?(parent))             
      # TODO ENABLE !! Puppet.warning "Gerrit was not installed in the default path (/opt/gerrit) on localhost. Will use /tmp (less optimal)" unless !warn      
      parent = '/tmp'
    end        
    
    path = parent+'/project_configs'
      
    path
  end
    
  def initialize(value={})
    super(value)
    
    #Puppet.debug "Initialising Git Provider"
    path = self.class.get_path(true)
            
    if (! File.directory?(path))             
      FileUtils.mkdir(path)
    end
    
    rest_info = self.class.get_rest_info()
    
    self.class.get_projects().each do |project|      
      project_path = path+'/'+project
      if (! File.directory?(project_path))      
        Dir.chdir(path) do        
          self.class.gitcmd('clone', 'ssh://'+rest_info[:username]+'@'+rest_info[:ip]+':'+rest_info[:ssh_port]+'/'+project)      # TODO SETUP SSH KEY !!
        end
            
        Dir.chdir(project_path) do
          self.class.gitcmd('pull', 'origin', 'refs/meta/config:refs/remotes/origin/meta/config')
          self.class.gitcmd('checkout', 'meta/config')        
        end      
      else
        Dir.chdir(project_path) do
          self.class.gitcmd('pull', 'origin', 'refs/meta/config:refs/remotes/origin/meta/config')  
        end   
      end
    end
        
    @property_flush = {} 
  end
  
  def self.get_configs    
    result = Hash.new
    
    get_projects().each do |project|
      result[project] = read_config(project)
    end
    
    result
  end
  
  def self.read_config(project)    
    path = get_path
    
    project_path = path+'/'+project
    
    #Puppet.debug "Reading config from "+project_path
    Dir.chdir(project_path) do
      if (File.file?('project.config'))
        config = gitcmd('config', '-f', 'project.config', '--list')  
        parsed = parse_config(config)
      
        parsed
      else
        Hash.new
      end
    end
  end
  
  def self.parse_config(rawData)
    result = Hash.new
    
    lines = rawData.split("\n")
    lines.each do |line|
      k_v = line.split("=")
      key = k_v[0]      
      key_parsed = key.split(".")
      
      #Puppet.debug "RAW LINE: "+line
      if key_parsed[0] == 'access' and key_parsed.count == 3
        reference = key_parsed[1]
        level = key_parsed[2]
        
        value = k_v[1]
        value_parsed = value.split(" ")
        
        group_index = value_parsed.index('group')        
        if (group_index != nil) 
          if (group_index == 0)
            value_parsed.delete_at(0)            
          elsif (group_index == 1)
            extra_value = value_parsed[0]
            level += "="+extra_value
            
            value_parsed.delete_at(0)
            value_parsed.delete_at(0) # Second entry becomes first entry after deleting first entry
          else
            Puppet.debug "Found access rule where 'group' identifier is not in normal location: "+line
            next
          end
          
          group = ""         
          value_parsed.each do |group_word|
            group += " " unless group == ""
            group += group_word
          end
          
          #Puppet.debug "PARSED: ["+reference+'] '+level +" = "+group

          if !result.has_key?(group)
            result[group] = Hash.new
          end
          groupConfig = result[group]
          
          if !groupConfig.has_key?(reference)
            result[group][reference] = Array.new
          end
          referenceConfig = result[group][reference]
                 
          result[group][reference].push level unless result[group][reference].include?(level)
        else
          Puppet.debug "Found access rule without 'group' identifier in the value: "+line
        end      
      end
    end
    
    result
  end
  
  def git_unset(project, key, value)
    path = self.class.get_path    
    project_path = path+'/'+project
    
    Dir.chdir(project_path) do
      if (File.file?('project.config'))
        config = self.class.gitcmd('config', '-f', 'project.config', '--unset-all', "\"#{key}\"", "\"#{value}\"")  
      end
    end
  end
  
  def git_add(project, key, value)
    path = self.class.get_path    
    project_path = path+'/'+project
    
    Dir.chdir(project_path) do
      if (File.file?('project.config'))
        config = self.class.gitcmd('config', '-f', 'project.config', '--add', "\"#{key}\"", "\"#{value}\"")  
      end
    end
  end
  
  def git_commit(project, commitMsg)
    path = self.class.get_path    
    project_path = path+'/'+project
    
    Dir.chdir(project_path) do
      self.class.gitcmd('commit', '-a', '-m', "\"#{commitMsg}\"")
      self.class.gitcmd('push', 'origin', 'HEAD:refs/meta/config')        
    end    
  end
      
  # REST INTERFACE !
  def self.get_projects
    result = Array.new
    
    get_objects(:projects).each do |name, object|
      result.push name
    end      
    result.push "All-Projects"
    
    result
  end
end