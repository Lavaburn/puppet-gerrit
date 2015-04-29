# Custom Type: Gerrit - Account

Puppet::Type.newtype(:gerrit_account) do
  @doc = "Gerrit Account"

  ensurable
      
  newparam(:name, :namevar => true) do
    desc "The account username"    
  end
  
  newproperty(:emails, :array_matching => :all) do
    desc "The account e-mail addresses"
  end
  
  newproperty(:real_name) do
    desc "The account full name"
  end
  
  newproperty(:ssh_keys, :array_matching => :all) do
    desc "The account SSH Public Keys"
  end

  newproperty(:http_password) do
    desc "The account HTTP Password (not used in every case)"
  end
  
  newproperty(:groups, :array_matching => :all) do
    desc "The groups that the account belongs to"
  end
end