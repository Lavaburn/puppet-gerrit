require File.join(File.dirname(__FILE__), '..', 'gerrit_rest')

Puppet::Type.type(:gerrit_project).provide :rest, :parent => Puppet::Provider::Rest do
  desc "REST provider for Gerrit Project"
  
  mk_resource_methods
  
  def flush    
    if @property_flush[:ensure] == :absent
      Puppet.warning "Deleting Projects is currently not supported! Don't use ensure => absent"  
    end
    
    if @property_flush[:ensure] == :present
#      Puppet.debug "Create Project"
      return createProject 
    end
    
#    Puppet.debug "Update Project"    
    updateProject
  end  

  def self.instances
    result = Array.new
    
    list = get_objects(:projects)    
    if list != nil
      list.each do |name, object|
        #Puppet.debug "PROJECT FOUND: "+object.inspect      
        list.push new(getProject(object["id"]))
      end
    end
    
    result
  end
  
  def self.getProject(id) 
    objectJSON = get_object(:projects, id)
            
    {
      :name          => objectJSON["name"],  
      :parent        => objectJSON["parent"],   
      :description   => objectJSON["description"],
#      :id            => objectJSON["id"],  
#      :kind          => objectJSON["kind"], 
#      :state         => objectJSON["state"],
      :ensure        => :present
    }
  end
  
  private
  def createProject      
    Puppet.debug "Creating Project "+resource[:name]

    # Required parameters
    resourceHash = {
      :name                 => resource[:name],
      :parent               => resource[:parent],
      :description          => resource[:description],
      :create_empty_commit  => true,
   }
    
    #API Call
#    Puppet.debug "createProject PARAMS = "+resourceHash.inspect      
    response = self.class.create_object(:projects, resourceHash)
  end
  
  def updateProject
    Puppet.debug "Updating Project "+resource[:name]
      
    updated = false    
    currentObject = self.class.getProject(@property_hash[:name])

    # Description
    if resource[:description] != currentObject[:description]
#      Puppet.debug "Updating Description for Project #{resource[:name]}"
          
      params = { :description => resource[:description] }
      response = self.class.update_object('projects/'+resource[:name]+'/description', params, false)
      
      updated = true
    end

    # Parent
    if resource[:parent] != currentObject[:parent]
#      Puppet.debug "Updating Parent for Project #{resource[:name]}"
          
      params = { :parent => resource[:parent] }
      response = self.class.update_object('projects/'+resource[:name]+'/parent', params, false)
      
      updated = true
    end
           
    if (!updated)
      # Project does not provide a general update function
      Puppet.warning("Gerrit API does not provide a general update function for the Project.")
    end
    
    # Update the current info    
    # @property_hash = self.class.getProject(resource[:name])    
  end
end