# Custom Type: Gerrit - Access Role

Puppet::Type.newtype(:gerrit_access_role) do
  @doc = "Gerrit Access Role"

  ensurable
      
  newparam(:name, :namevar => true) do
    desc "The access role name (\"GROUP in PROJECT\")"    
  end
  
  newproperty(:project) do
    desc "The project"
    
    defaultto 'All-Projects'
  end
  
  newproperty(:group) do
    desc "The user group"
    
    defaultto 'All Users'
  end
  
  newproperty(:rules) do
    desc "The rule hash"
  end
  
  autorequire(:package) do
    ['git']
  end
end