require File.join(File.dirname(__FILE__), '..', 'gerrit_git')

Puppet::Type.type(:gerrit_access_role).provide :git, :parent => Puppet::Provider::Git do
  desc "Git provider for Gerrit Access Role"
  
  mk_resource_methods
  
  def flush           
    if @property_flush[:ensure] == :absent
      Puppet.debug "Delete Access Role"
      return deleteRole
    end
    
    if @property_flush[:ensure] == :present
      Puppet.debug "Create Access Role"
      return createRole
    end
    
    Puppet.debug "Update Access Role"
    updateRole
  end  

  def self.instances
    result = Array.new
    
    get_configs().each do |project, config|
      config.each do |group, rules|
  
        #Puppet.debug "Config loaded: -#{group} in #{project}-"
        
        role = {
          :name     => "#{group} in #{project}",
          :project  => project,
          :group    => group,
          :rules    => rules,
          :ensure   => :present,
        }        
        
        result.push new(role)
      end
    end
    
    result
  end
  
  def getConfig(name)    
    role = nil    
    parts = name.split(" in ")
    
    self.class.get_configs().each do |project, config|
      config.each do |group, rules|        
        if group == parts[0] and project == parts[1]  
          role = {
            :name     => "#{group} in #{project}",
            :project  => project,
            :group    => group,
            :rules    => rules,
            :ensure   => :present,
          }   
        end    
      end
    end

    role
  end
  
  # TYPE SPECIFIC  
  private
  def createRole      
    Puppet.debug "Creating Role "+resource[:name]
      
    found = false
    getProjectGroups(resource[:project]).each do |uuid, group|
      if (group == resource[:group]) 
        found = true
      end
    end
    if !found
      objectJSON = self.class.get_object(:groups, resource[:group])
      uuid = objectJSON['id']
      addProjectGroup(resource[:project], uuid, resource[:group])
    end  
    
    resource[:rules].each do |reference, levels|       
      levels.each do |level| 
        git_add(resource[:project], "access.#{reference}.#{level}", "group #{resource[:group]}")      
      end
    end
      
    git_commit(resource[:project], 'Created new Access Role '+resource[:name])
  end

  def updateRole
    Puppet.debug "Updating Role "+resource[:name]
      
    currentObject = getConfig(@property_hash[:name])

    # Rules Changed
    if resource[:rules] != currentObject[:rules]
      resource[:rules].each do |reference, levels|
        if currentObject[:rules].has_key?(reference)          
          oldLevels = currentObject[:rules][reference]
            
          levels.each do |addLevel|
            if !oldLevels.include?(addLevel)
              git_add(resource[:project], "access.#{reference}.#{addLevel}", "group #{resource[:group]}") 
            end
          end
          
          oldLevels.each do |removeLevel|
            if !levels.include?(removeLevel)              
              git_unset(resource[:project], "access.#{reference}.#{removeLevel}", "group #{resource[:group]}")      
            end
          end
        else
          levels.each do |level|
            git_add(resource[:project], "access.#{reference}.#{level}", "group #{resource[:group]}")
          end
        end 
      end
      
      currentObject[:rules].each do |reference, levels|
        if ! resource[:rules].has_key?(reference)
          levels.each do |level|
            git_unset(resource[:project], "access.#{reference}.#{level}", "group #{resource[:group]}")
          end
        end
      end
      
      updated = true
      
      git_commit(resource[:project], 'Updated Access Role '+resource[:name])
    end

    if (!updated)
      Puppet.warning("Only rules are updateable for Access Role. The name should be in format -GROUP in PROJECT- !!")
    end
    
    # Update the current info    
    # @property_hash = getConfig(resource[:name])    
  end
  
  def deleteRole      
    Puppet.debug "Deleting Role "+resource[:name]
      
    config = getConfig(@property_hash[:name])   
    if config != nil
      config[:rules].each do |reference, levels|       
        levels.each do |level| 
          git_unset(resource[:project], "access.#{reference}.#{level}", "group #{resource[:group]}")      
        end
      end
    end
      
    git_commit(resource[:project], 'Removed Access Role '+resource[:name])
  end
  
  def getProjectGroups(project)    
    result = Hash.new
    
    path = self.class.get_path
    project_path = path+'/'+project
        
    Dir.chdir(project_path) do
      if (File.file?('groups'))                
        count = 0
        file = File.new("groups", "r")
        while (line = file.gets)
          if (count > 1)
            parts = line.split("\t")                        
            result[parts[0]] = parts[1].sub("\n", "")
          end
          
          count += 1
        end
        file.close
      end
    end

    result      
  end
  
  def addProjectGroup(project, uuid, name)
    Puppet.debug "Adding Group to Project: #{uuid} = #{name}"

    path = self.class.get_path
    project_path = path+'/'+project
    
    Dir.chdir(project_path) do
      if (!File.file?('groups'))
        File.open("groups", 'w') { |file| 
          file.write("# UUID\t\t\t\t\t\tGroup Name\n") 
          file.write("#\n") 
        }
      end
     
      File.open("groups", 'a') { |file| 
        file.write("#{uuid}\t#{name}\n") 
      }
    end    
  end  
end