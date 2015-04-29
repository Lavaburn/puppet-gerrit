begin
  require 'rest-client' if Puppet.features.rest_client?
  require 'json' if Puppet.features.json?   
  require 'uri' # TODO FEATURE
rescue LoadError => e
  Puppet.info "Gerrit Puppet module requires 'rest-client' and 'json' ruby gems."
end

class Puppet::Provider::Rest < Puppet::Provider
  desc "Gerrit API REST calls"
  
  confine :feature => :json
  confine :feature => :rest_client
  
  def initialize(value={})
    super(value)
    @property_flush = {} 
  end
    
  def self.get_rest_info
    # TODO - read the below variables from a config file
    
    ip = '105.235.209.24'
    port = '8082'
    ssh_port = '29418'
    username = 'nicolas'
    password = 'password'

    { :ip       => ip,
      :port     => port,
      :ssh_port => ssh_port,
      :username => username,
      :password => password
    }
  end

  def exists?    
    @property_hash[:ensure] == :present
  end
  
  def create
    @property_flush[:ensure] = :present
  end

  def destroy        
    @property_flush[:ensure] = :absent
  end
          
  def self.prefetch(resources)        
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end  
  
  def self.get_objects(endpoint, json_output = true)    
#    Puppet.debug "GERRIT-API (generic) get_objects: #{endpoint}"
    
    response = http_get("#{endpoint}/", json_output)
#    Puppet.debug("GET #{endpoint} to Gerrit API returned #{response.inspect}")

    response
  end
  
  def self.get_object(endpoint, id, json_output = true)    
#    Puppet.debug "GERRIT-API (generic) get_object: #{endpoint}/#{id}"
    
    enc = URI.escape(id)
    response = http_get("#{endpoint}/#{enc}", json_output)      
#    Puppet.debug("GET #{endpoint}/#{id} on Gerrit API returned #{response.inspect}")
    
    response
  end
  
  def self.create_object(endpoint, objectJSON, title = :name, json_output = true)    
#    Puppet.debug "GERRIT-API (generic) create_object: #{endpoint}/#{objectJSON[title]}"

    id = URI.escape(objectJSON[title])
    response = http_put("#{endpoint}/#{id}", objectJSON, json_output)      
    Puppet.debug("PUT #{endpoint}/#{objectJSON[:name]} on Gerrit API returned #{response.inspect}")

    response
  end

  def self.create_object_raw(endpoint, object)    
    Puppet.debug "GERRIT-API (generic) create_object_raw: #{endpoint}"
  
    response = http_post("#{endpoint}", object)      
    Puppet.debug("POST #{endpoint} on Gerrit API returned #{response.inspect}")
  
    response
  end

  def self.create_object_nodata(endpoint)    
    Puppet.debug "GERRIT-API (generic) create_object_nodata: #{endpoint}"
  
    response = http_put_nodata("#{endpoint}")      
    Puppet.debug("PUT #{endpoint} on Gerrit API returned #{response.inspect}")
  
    response
  end

  def self.delete_object(endpoint)    
    Puppet.debug "GERRIT-API (generic) delete_object: #{endpoint}"
  
    response = http_delete("#{endpoint}")      
    Puppet.debug("DELETE #{endpoint} on Gerrit API returned #{response.inspect}")
  
    response
  end
  
  def self.update_object(endpoint, objectJSON, json_output = true)    
#    Puppet.debug "GERRIT-API (generic) update_object: #{endpoint}"
    
    enc = URI.escape(endpoint)
    response = http_put("#{enc}", objectJSON, json_output)      
    Puppet.debug("PUT #{endpoint} on Gerrit API returned #{response.inspect}")
  
    response
  end
  
  private
  def self.http_get(endpoint, json_output = true) 
#    Puppet.debug "GERRIT-API (generic) http_get: #{endpoint}"
    
    resource = createResource(endpoint)
    
    begin      
      response = resource.get(:accept => :json) { |response, request, result, block|
        case response.code
          when 404
            if (!json_output)
              return ""
            else
              raise "404 - NotFound for Gerrit API on #{resource.inspect} and expected JSON formatting."
            end
          else
            response.return!(request, result, &block)
        end          
      }        
    rescue => e
      Puppet.debug "Gerrit API response: "+e.inspect
      raise "Unable to contact Gerrit API on #{resource.inspect}"
    end
    
    if response != nil
      response = response.sub(")]}'", '')
    end
        
    if (json_output)
      json = convertResponseToJSON(response) 
    else
      json = response
    end
    
    json   
  end
  
  def self.http_put(endpoint, paramJSON, json_output = true) 
#    Puppet.debug "GERRIT-API (generic) http_put: #{endpoint}"
    
    resource = createResource(endpoint)
    
    begin            
      response = resource.put paramJSON.to_json, :content_type => :json, :accept => :json
    rescue => e
      Puppet.debug "Gerrit API response: "+e.inspect
      raise "Unable to contact Gerrit API on #{resource.inspect}"
    end

    response = response.sub(")]}'", '')  
    if (json_output)
      json = convertResponseToJSON(response) 
    else
      json = response
    end
    
    json    
  end

  def self.http_put_nodata(endpoint, json_output = true) 
    Puppet.debug "GERRIT-API (generic) http_put_nodata: #{endpoint}"
   
    resource = createResource(endpoint)
    
   begin            
     response = resource.put Hash.new.to_json, :content_type => :json, :accept => :json
    rescue => e
      Puppet.debug "Gerrit API response: "+e.inspect
      raise "Unable to contact Gerrit API on #{resource.inspect}"
    end

    response = response.sub(")]}'", '')  
    if (json_output)
      json = convertResponseToJSON(response) 
    else
      json = response
    end
    
    json    
  end
  
  def self.http_post(endpoint, paramRaw, json_output = true) 
    Puppet.debug "GERRIT-API (generic) http_post: #{endpoint}"

    resource = createResource(endpoint)
    
    begin            
      response = resource.post paramRaw, :content_type => :text, :accept => :json
    rescue => e
      Puppet.debug "Gerrit API response: "+e.inspect
      raise "Unable to contact Gerrit API on #{resource.inspect}"
    end
  
    response = response.sub(")]}'", '')  
    if (json_output)
      json = convertResponseToJSON(response) 
    else
      json = response
    end
    
    json    
  end

  def self.http_delete(endpoint) 
    Puppet.debug "GERRIT-API (generic) http_delete: #{endpoint}"

    resource = createResource(endpoint)
    
    begin            
      response = resource.delete
    rescue => e
      Puppet.debug "Gerrit API response: "+e.inspect
      raise "Unable to contact Gerrit API on #{resource.inspect}"
    end
    
    response 
  end
  
  def self.createResource(endpoint)
    rest = get_rest_info
    
    url = "http://#{rest[:ip]}:#{rest[:port]}/a/#{endpoint}"
    
    resource = RestClient::Resource.new(url, :user => rest[:username], :password => rest[:password])
    
    resource
  end
  
  def self.convertResponseToJSON(response)
    begin    
      responseJson = JSON.parse(response)
    rescue
      raise "Could not parse the JSON response from Gerrit API: #{response}"
    end

    responseJson
  end
end