require File.join(File.dirname(__FILE__), '..', 'gerrit_rest')

Puppet::Type.type(:gerrit_account).provide :rest, :parent => Puppet::Provider::GerritRest do
  desc "REST provider for Gerrit Account"
  
  mk_resource_methods
  
  def flush    
    if @property_flush[:ensure] == :absent
#      Puppet.debug "Delete Account"
      Puppet.warning "Deleting Accounts is currently not supported! Will set the account inactive."
    end
    
    if @property_flush[:ensure] == :present
#      Puppet.debug "Create Account"
      return createAccount
    end
    
#    Puppet.debug "Update Account"
    updateAccount
  end  

  def self.instances
    result = Array.new
        
    list = get_objects(:groups)    
    if list != nil
      list.each do |name, object|  
        get_objects("groups/#{object['id']}/members").each do |aobject|
          #Puppet.debug "ACCOUNT FOUND: "+aobject["_account_id"].inspect          
          # TODO MAKE SURE IT'S UNIQUE ??
          result.push new(getAccount(aobject["_account_id"]))
        end
      end
    end
    
    result
  end
  
  # TYPE SPECIFIC  
  def self.getAccount(id) 
    objectJSON = get_object(:accounts, "#{id}")
    
    enc = URI.escape("#{id}")
    
    active = get_object("accounts/#{enc}", "active", false)
    if active != nil
      active = active.gsub("\n", "")      
    end
    
    http_password = get_object("accounts/#{enc}", "password.http", false)
    if http_password != nil
      http_password = http_password.gsub("\n", "")
      http_password = http_password.gsub("\"", "")      
    end
    
    emails = Array.new
    emailsJSON = get_objects("accounts/#{enc}/emails")
    emailsJSON.each do |key|
      emails.push key["email"]
    end
    
    sshKeys = Array.new
    sshKeysJSON = get_objects("accounts/#{enc}/sshkeys")
    sshKeysJSON.each do |key|
      sshKeys.push key["ssh_public_key"]
    end
    
    groups = Array.new
    groupsJSON = get_objects("accounts/#{enc}/groups")
    groupsJSON.each do |key|
      groups.push key["name"]
    end
    groups.delete "All Users"
    groups.delete "Anonymous Users"
    groups.delete "Registered Users"  
    
    groups.sort!    # .sort returns new array, .sort! performs it on the object itself
        
    if (active == "ok")
      state = :present
    else
      state = :absent
    end
    
    if objectJSON["name"] == ""
      name = nil
    else
      name = objectJSON["name"]       
    end
        
    {
      :name          => objectJSON["username"],   
      :real_name     => name,  
      :http_password => http_password,
        
      :emails        => emails,     
      :ssh_keys      => sshKeys,
      :groups        => groups,
      :ensure        => state
    }
  end
  
  private
  def createAccount      
    Puppet.debug "Creating Account "+resource[:name]
    
    groups = Array.new
    groups = resource[:groups] unless resource[:groups] == nil
    groups.push "All Users" unless groups.include? "All Users"
        
    email = resource[:emails].first unless resource[:emails] == nil
    ssh_key = resource[:ssh_keys].first unless resource[:ssh_keys] == nil

    # Required parameters
    resourceHash = {
      :username         => resource[:name],
      :name             => resource[:real_name],
      :email            => email,
      :ssh_key          => ssh_key,
      :http_password    => resource[:http_password],
      :groups           => groups,
    }
    
    #API Call
#    Puppet.debug "createAccount PARAMS = "+resourceHash.inspect      
    response = self.class.create_object(:accounts, resourceHash, :username)
  end

  def updateAccount
    Puppet.debug "Updating Account "+resource[:name]
      
    enc = URI.escape(resource[:name])
    
    updated = false    
    currentObject = self.class.getAccount(@property_hash[:name])

    # Real Name
    if resource[:real_name] != currentObject[:real_name]
      Puppet.debug "Updating Real Name for Account #{resource[:name]}"

      if resource[:real_name] == nil
        response = self.class.delete_object('accounts/'+enc+'/name')
      else
        params = { :name => resource[:real_name] }
        response = self.class.update_object('accounts/'+enc+'/name', params, false)
      end
        
      updated = true
    end

    # E-mail
    if resource[:emails] != currentObject[:emails]
      Puppet.debug "Updating E-mail for Account #{resource[:name]}"

      resource[:emails] = Array.new unless resource[:emails] != nil       
      currentObject[:emails] = Array.new unless currentObject[:emails] != nil       
       
      resource[:emails].each { |address|
        if ! currentObject[:emails].include? address
          Puppet.debug "Add E-Mail "+address+" to account #{resource[:name]}"     
          
          params = { :email => address, :no_confirmation => true }
          response = self.class.create_object("accounts/#{enc}/emails", params, :email)    
        end        
      }

      currentObject[:emails].each { |address|
        if ! resource[:emails].include? address 
          Puppet.debug "Remove E-Mail "+address+" from account #{resource[:name]}"      
          
          enc2 = URI.escape(address)
          response = self.class.delete_object("accounts/#{enc}/emails/"+enc2)
        end        
      }
      
      updated = true
    end
    
    # SSH Keys
    if resource[:ssh_keys] != currentObject[:ssh_keys]
      Puppet.debug "Updating SSH Keys for Account #{resource[:name]}"
      
      sshKeys = Hash.new
      sshKeysJSON = self.class.get_objects("accounts/#{enc}/sshkeys")
      sshKeysJSON.each do |key|
        sshKeys[key["seq"]] = key["ssh_public_key"]
      end
      
      resource[:ssh_keys] = Array.new unless resource[:ssh_keys] != nil       
      currentObject[:ssh_keys] = Array.new unless currentObject[:ssh_keys] != nil       
              
      resource[:ssh_keys].each { |key|
        if ! currentObject[:ssh_keys].include? key
          Puppet.debug "Create SSH Key "+key     
          response = self.class.create_object_raw('accounts/'+resource[:name]+'/sshkeys', key)     
        end        
      }
      
      currentObject[:ssh_keys].each { |key|
        if ! resource[:ssh_keys].include? key
          Puppet.debug "Delete SSH Key "+key     
          seq = sshKeys.key(key)
          response = self.class.delete_object('accounts/'+resource[:name]+"/sshkeys/#{seq}")
        end        
      }
        
      updated = true
    end
        
    # HTTP Password
    if resource[:http_password] != currentObject[:http_password]
      Puppet.debug "Updating HTTP Password for Account #{resource[:name]}"

#      params = { :real_name => resource[:real_name] }
#      response = self.class.update_object('accounts/'+resource[:name]+'/name', params, false)
    
      updated = true
    end
            
    # Groups
    if resource[:groups] != currentObject[:groups]
      Puppet.debug "Updating Groups for Account #{resource[:name]}"
      
      resource[:groups] = Array.new unless resource[:groups] != nil       
      currentObject[:groups] = Array.new unless currentObject[:groups] != nil       
       
      resource[:groups].each { |group|
        if ! currentObject[:groups].include? group
          Puppet.debug "Add to Group "+group     
          
          enc2 = URI.escape(group)
          response = self.class.create_object_nodata('groups/'+enc2+'/members/'+enc)    
        end        
      }

      currentObject[:groups].each { |group|
        if ! resource[:groups].include? group
          Puppet.debug "Remove from Group "+group     
          
          enc2 = URI.escape(group)
          response = self.class.delete_object('groups/'+enc2+'/members/'+enc)
        end        
      }
      
      updated = true
    end
    
    # Active/Inactive
# TODO - GIVES ERROR !!
#    if @property_flush[:ensure] != resource[:ensure]
#      Puppet.debug "Setting status for Account #{resource[:name]} to "+@property_flush[:ensure]
#
#      Puppet.debug "TODO"
##      params = { :real_name => resource[:real_name] }
##      response = self.class.update_object('accounts/'+resource[:name]+'/name', params, false)
#    
#      updated = true
#    end
    
    if (!updated)
      # Account does not provide a general update function
      Puppet.warning("Gerrit API does not provide a general update function for the Account.")
    end
    
    # Update the current info    
    # @property_hash = self.class.getProject(resource[:name])    
  end
end