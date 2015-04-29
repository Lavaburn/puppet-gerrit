# Custom Type: Gerrit - Group

Puppet::Type.newtype(:gerrit_group) do
  @doc = "Gerrit Group"

  ensurable
      
  newparam(:name, :namevar => true) do
    desc "The group name"    
  end
  
  newproperty(:description) do
    desc "The group description"
  end
end