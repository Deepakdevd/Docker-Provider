#!/usr/local/bin/ruby


@os_type = ENV["OS_TYPE"]
require "tomlrb"

require_relative "ConfigParseErrorLogger"

@configMapMountPath = "/etc/config/settings/agent-settings"
@configSchemaVersion = ""

@disableTelemetry = false

def is_number?(value)
  true if Integer(value) rescue false
end

# check if it is number and greater than 0
def is_valid_number?(value)
  return !value.nil? && is_number?(value) && value.to_i > 0
end

# check if it is a valid waittime
def is_valid_waittime?(value, default)
  return !value.nil? && is_number?(value) && value.to_i >= default / 2 && value.to_i <= 3 * default
end

# Use parser to parse the configmap toml file to a ruby structure
def parseConfigMap
  begin
    # Check to see if config map is created
    if (File.file?(@configMapMountPath))
      puts "config::configmap container-azm-ms-agentconfig for common agent settings mounted, parsing values"
      parsedConfig = Tomlrb.load_file(@configMapMountPath, symbolize_keys: true)
      puts "config::Successfully parsed mounted config map"
      return parsedConfig
    else
      puts "config::configmap container-azm-ms-agentconfig for common agent settings not mounted, using defaults"
      return nil
    end
  rescue => errorStr
    ConfigParseErrorLogger.logError("Exception while parsing config map for agent settings : #{errorStr}, using defaults, please check config map for errors")
    return nil
  end
end

# Use the ruby structure created after config parsing to set the right values to be used as environment variables
def populateSettingValuesFromConfigMap(parsedConfig)
  begin
    if !parsedConfig.nil? && !parsedConfig[:agent_settings].nil?
      telemetry_config = parsedConfig[:agent_settings][:telemetry_config]
      if !telemetry_config.nil? && !telemetry_config[:disable_telemetry].nil?
        @disableTelemetry = telemetry_config[:disable_telemetry]
        puts "Using config map value: disable_telemetry = #{@disableTelemetry}"
      end
    end
  rescue => errorStr
    puts "config::error:Exception while reading config settings for agent configuration setting - #{errorStr}, using defaults"
  end
end

@configSchemaVersion = ENV["AZMON_AGENT_CFG_SCHEMA_VERSION"]
puts "****************Start Config Processing********************"
if !@configSchemaVersion.nil? && !@configSchemaVersion.empty? && @configSchemaVersion.strip.casecmp("v1") == 0 #note v1 is the only supported schema version , so hardcoding it
  configMapSettings = parseConfigMap
  if !configMapSettings.nil?
    populateSettingValuesFromConfigMap(configMapSettings)
  end
else
  if (File.file?(@configMapMountPath))
    ConfigParseErrorLogger.logError("config::unsupported/missing config schema version - '#{@configSchemaVersion}' , using defaults, please use supported schema version")
  end
end

def get_command_windows(env_variable_name, env_variable_value)
  return "#{env_variable_name}=#{env_variable_value}\n"
end

if !@os_type.nil? && !@os_type.empty? && @os_type.strip.casecmp("windows") == 0
  # Write the settings to file, so that they can be set as environment variables
  file = File.open("setcommonagentenv.txt", "w")
  if !file.nil?
    if @disableTelemetry
      commands = get_command_windows("DISABLE_TELEMETRY", @disableTelemetry)
      file.write(commands)
    end
    # Close file after writing all environment variables
    file.close
    puts "****************End Config Processing********************"
  else
    puts "Exception while opening file for writing config environment variables for WINDOWS LOG"
    puts "****************End Config Processing********************"
  end
else
  # Write the settings to file, so that they can be set as environment variables
  file = File.open("common_agent_config_env_var", "w")
  if !file.nil?
    if @disableTelemetry
      file.write("export DISABLE_TELEMETRY=#{@disableTelemetry}\n")
    end

    # Close file after writing all environment variables
    file.close
  else
    puts "Exception while opening file for writing config environment variables"
    puts "****************End Config Processing********************"
  end
end
