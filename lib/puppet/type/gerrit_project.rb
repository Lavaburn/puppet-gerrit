# Custom Type: Gerrit - Project

Puppet::Type.newtype(:gerrit_project) do
  @doc = "Gerrit Project"

  ensurable
      
  newparam(:name, :namevar => true) do
    desc "The project name"    
  end
  
  newproperty(:parent) do
    desc "The project parent"
    
    defaultto 'All-Projects'
  end
  
  newproperty(:description) do
    desc "The project description"
  end
end