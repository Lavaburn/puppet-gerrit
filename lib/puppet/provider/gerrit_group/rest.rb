require File.join(File.dirname(__FILE__), '..', 'gerrit_rest')

Puppet::Type.type(:gerrit_group).provide :rest, :parent => Puppet::Provider::Rest do
  desc "REST provider for Gerrit Group"
  
  mk_resource_methods
  
  def flush    
    if @property_flush[:ensure] == :absent
#      Puppet.debug "Delete Group"
      Puppet.warning "Deleting Groups is currently not supported!"      
    end
    
    if @property_flush[:ensure] == :present
#      Puppet.debug "Create Group"
      return createGroup
    end
    
#    Puppet.debug "Update Group"
    updateGroup
  end  

  def self.instances
    get_objects(:groups).collect do |name, object|
#      Puppet.debug "GROUP FOUND: "+getGroup(name).inspect      
      new(getGroup(name))
    end
  end
  
  # TYPE SPECIFIC  
  def self.getGroup(id) 
    objectJSON = get_object(:groups, "#{id}")
        
    {
      :name          => objectJSON["name"],   
      :description   => objectJSON["description"],  
      :ensure        => :present
    }
  end
  
  private
  def createGroup
    Puppet.debug "Creating Group "+resource[:name]
    
    # Required parameters
    resourceHash = {
      :name         => resource[:name],
      :description  => resource[:description],
    }
    
    #API Call
#    Puppet.debug "createGroup PARAMS = "+resourceHash.inspect      
    response = self.class.create_object(:groups, resourceHash)
  end

  def updateGroup
    Puppet.debug "Updating Group "+resource[:name]
    
    updated = false    
    currentObject = self.class.getGroup(@property_hash[:name])

    # Description
    if resource[:description] != currentObject[:description]
#      Puppet.debug "Updating Description for Group #{resource[:name]}"
          
      params = { :description => resource[:description] }
      response = self.class.update_object('groups/'+resource[:name]+'/description', params, false)
      
      updated = true
    end
         
    if (!updated)
      # Group does not provide a general update function
      Puppet.warning("Gerrit API does not provide a general update function for the Group.")
    end
    
    # Update the current info    
    # @property_hash = self.class.getProject(resource[:name])    
  end
end