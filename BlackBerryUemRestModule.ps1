$ErrorActionPreference = 'Stop'; Set-StrictMode -Version 5.1

enum Environment {
    PROD
    UAT
    DEV
}

enum Region {
    Region1
    Region2
}

$script:TestMode = $true

$Config = @{
    Env = @{
        PROD = @{
            Domain = 'domain.com'
            Regions = @{
                Region1 = @{
                    Region = 'Region1'
                    PrimaryServer = 'prod-pod1.domain.com'
                    SecondaryServers = @('prod-pod1-sec1.domain.com', 'prod-pod1-sec2.domain.com')
                    TenantGuid = '00000000-0000-0000-0000-000000000000'
                    Port = 18084
                }
                Region2 = @{
                    Region = 'Region2'
                    PrimaryServer = 'prod-pod2.domain.com'
                    SecondaryServers = @('prod-pod2-sec1.domain.com', 'prod-pod2-sec2.domain.com')
                    TenantGuid = '00000000-0000-0000-0000-000000000000'
                    Port = 18084
                }
            }
        }
        UAT = @{
            Domain = 'uat.domain.com'
            Regions = @{
                Region1 = @{
                    Region = 'Region1'
                    PrimaryServer = 'uat-pod1.domain.com'
                    SecondaryServers = @('uat-pod1-sec1.domain.com', 'uat-pod1-sec2.domain.com')
                    TenantGuid = '00000000-0000-0000-0000-000000000000'
                    Port = 18084
                }
                Region2 = @{
                    Region = 'Region2'
                    PrimaryServer = 'uat-pod2.domain.com'
                    SecondaryServers = @('uat-pod2-sec1.domain.com', 'uat-pod2-sec2.domain.com')
                    TenantGuid = '00000000-0000-0000-0000-000000000000'
                    Port = 18084
                }
            }
        }
        DEV = @{
            Domain = 'dev.domain.com'
            Regions = @{
                Region1 = @{
                    Region = 'Region1'
                    PrimaryServer = 'dev-pod1.domain.com'
                    SecondaryServers = @('dev-pod1-sec1.domain.com', 'dev-pod1-sec2.domain.com')
                    TenantGuid = '00000000-0000-0000-0000-000000000000'
                    Port = 18084
                }
                Region2 = @{
                    Region = 'Region2'
                    PrimaryServer = 'dev-pod2.domain.com'
                    SecondaryServers = @('dev-pod2-sec1.domain.com', 'dev-pod2-sec2.domain.com')
                    TenantGuid = '00000000-0000-0000-0000-000000000000'
                    Port = 18084
                }
            }
        }
    }

    FunctionParams = @{
        'Get-UemAuthToken'   = @{
        'Uri'     = '/api/v1/util/authorization'
        'Method'  = 'POST'
        'Headers' = @{
            'Content-Type' = 'application/vnd.blackberry.authorizationrequest-v1+json'
        }
            'Body'    = @{
                'provider' = 'LOCAL'
                'username' = ''
                'password' = ''
            }
        }
        'Ping-UemHost'       = @{
            'Uri'     = '/api/v1/util/ping'
            'Method'  = 'GET'
            'Headers' = @{
                'ContentType'   = 'application/vnd.blackberry.pingrequest-v1+json'
                'authorization' = ''
            }
        }
        'Ping-UemHostSecure' = @{
            'Uri'     = '/api/v1/ping'
            'Method'  = 'GET'
            'Headers' = @{
                'content-type'  = 'application/vnd.blackberry.pingrequest-v1+json'
                'authorization' = ''
            }
        }
        'Get-UemUserDevices' = @{
            'Uri'     = '/api/v1/users/{userGuid}/userDevices'
            'Method'  = 'GET'
            'Headers' = @{
                'content-type'  = 'application/vnd.blackberry.userdevices-v1+json'
                'authorization' = ''
            }
        }
        'Search-UemUser' = @{
            'Uri'     = '/api/v1/users?query={0}={1}'
            'Method'  = 'GET'
            'Headers' = @{
                'content-type'  = 'application/vnd.blackberry.users-v1+json'
                'authorization' = ''
            }
        }      
        'Search-UemAppGroup' = @{
            'Uri'     = '/api/v1/applicationGroups?query=name={$name}'
            'Method'  = 'GET'
            'Headers' = @{
                'content-type'  = 'application/vnd.blackberry.applicationgroups-v1+json'
                'authorization' = ''
            }
        }
        'Send-UemUserDeviceCommand' = @{
            'Uri'     = '/api/v1/users/{userGuid}/userDevices/{userDeviceGuid}/commands'
            'Method'  = 'POST'
            'Headers' = @{
                'content-type'  = 'application/vnd.blackberry.command-v1+json'
                'authorization' = ''
            }
        }
        'Get-UemUserDeviceCommandStatus' = @{
            'Uri'     = '/api/v1/users/{userGuid}/userDevices/{userDeviceGuid}/commands/{commandGuid}'
            'Method'  = 'GET'
            'Headers' = @{
                'content-type'  = 'application/vnd.blackberry.command-v1+json'
                'authorization' = ''
            }
        }
    }
}

function Search-UemUser
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('PROD', 'UAT', 'DEV')]
        [string]$Environment,

        [Parameter(Mandatory = $false)]
        [string]$Region,

        [Parameter(Mandatory = $true)]
        [ValidateSet('emailAddress', 'username')]
        [string]$SearchField,

        [Parameter(Mandatory = $true)]
        [string]$SearchString,

        [Parameter(Mandatory = $false)]
        [pscredential]$Credential
    )

    $functionName = $MyInvocation.MyCommand.Name

    $params = $Config.FunctionParams.$functionName
    $params.Uri = $params.Uri -f $SearchField, $SearchString

    if($Region)
    {
        Invoke-UemApiCall -Environment $Environment -Region $Region -Params $params
    }
    else 
    {
        Invoke-UemApiCall -Environment $Environment -Params $params
    }
}

function Invoke-UemApiCall
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('PROD', 'UAT', 'DEV')]
        [string]$Environment,

        [Parameter(Mandatory = $false)]
        [string]$Region,

        [Parameter(Mandatory = $true)]
        [hashtable]$Params
    )

    if(!$Credential) 
    {
        $Credential = Get-Credential -Message "Enter your UEM credentials for $Environment"
    }

    if($PSBoundParameters['Region']) 
    {
        $instances = Get-UemInstance $Environment $Region
    } 
    else 
    {
        $instances = Get-UemInstance $Environment
    }

    $responses = @()

    foreach($instance in $instances) 
    {        
        $servers = @($instance.PrimaryServer) + $instance.SecondaryServers

        foreach($server in $servers)
        {
            try 
            {
                $uri = "https://{0}:{1}/{2}" -f $server, $instance.Port, $instance.TenantGuid

                $param = $Params.PSObject.Copy()

                $param.Uri = $uri + $param.Uri

                $param.Headers.authorization = Get-UemAuthToken -Environment $Environment -Region $Instance.Region -Credential $Credential

                $response = Invoke-RestMethod @param

                $responses += $response
            }
            catch
            {
                Write-Warning "Request failed on $($environment): $($instance.Region): $($server). Trying the next one..."
            }
        }
    }
}

function Ping-UemHost
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('PROD', 'UAT', 'DEV')]
        [string]$Environment,

        [Parameter(Mandatory = $false)]
        [string]$Region,

        [Parameter(Mandatory = $false)]
        [pscredential]$Credential
    )

    $functionName = $MyInvocation.MyCommand.Name

    $params = $Config.FunctionParams.$functionName

    Invoke-RestMethod @params
}

function Get-UemInstance
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet('PROD', 'UAT', 'DEV')]
        [string]$Environment,

        [Parameter(Mandatory = $false)]
        [string]$Region
    )

    if($PSBoundParameters['Region']) 
    {
        $instances = $Config.Env.$Environment.Regions.$Region
    } 
    else 
    {
        $instances = $Config.Env.$Environment.Regions.Keys | % { $Config.Env.$Environment.Regions.$_ }
    }

    return $instances
}

function Get-UemAuthToken
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('PROD', 'UAT', 'DEV')]
        [string]$Environment,

        [Parameter(Mandatory = $true)]
        [string]$Region,

        [Parameter(Mandatory = $true)]
        [pscredential]$Credential
    )

    $instance = $Config.Env.$Environment.Regions.$Region

    $uri = "https://{0}:{1}/{2}" -f $instance.PrimaryServer, $instance.Port, $instance.TenantGuid
    
    $params = $Config.FunctionParams.($MyInvocation.MyCommand.Name).PSObject.Copy()

    $params.Uri = $uri + $params.Uri
    $params.Body.username = $Credential.UserName
    $params.Body.password = $Credential.GetNetworkCredential().Password | ConvertTo-Base64

    $response = Invoke-RestMethod @params

    return "Bearer $($response.Headers['authorization'])"
}